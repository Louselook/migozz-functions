// lib/core/utils/pages/support/support_screen_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sending...")));

      String? base64File;
      String? fileName;

      if (selectedFile != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(selectedFile!);
        await reader.onLoad.first;

        final bytes = reader.result as List<int>;
        base64File = base64Encode(bytes);
        fileName = selectedFile!.name;
      }

      final ticket = {
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "message": _messageCtrl.text.trim(),
        "createdAt": DateTime.now().toUtc().toIso8601String(),
        "fileName": fileName,
        "fileBase64": base64File,
        "status": "pending",
      };

      await FirebaseFirestore.instance.collection("supportTickets").add(ticket);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket enviado correctamente.")),
      );

      context.go('/login');
    } catch (e) {
      debugPrint("ERROR al enviar ticket: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending ticket: $e")));
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  html.File? selectedFile;

  Future<void> pickFile() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select File')));
      return;
    }

    try {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files?.first;
        if (file != null) {
          setState(() => selectedFile = file);
        }
      });
    } catch (e, st) {
      debugPrint('Error pickFile: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryText("Support / Report a Problem")),
                ],
              ),
            ),
            Expanded(
              child: isDesktop || isTablet
                  ? _buildTwoColumnLayout()
                  : _buildSingleColumnLayout(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GradientButton(
                  width: double.infinity,
                  radius: 19,
                  onPressed: _onSubmit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      SecondaryText("Send"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildFormCard()),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [_buildFormCard(), const SizedBox(height: 20)]),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameCtrl,
              label: "Your Name",
              placeholder: "Enter your name",
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _emailCtrl,
              label: "Email Address",
              placeholder: "Enter your email",
              icon: Icons.email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please complete all required fields";
                }
                if (!value.contains('@')) {
                  return "Enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _messageCtrl,
              label: "Describe the Issue",
              placeholder: "Explain what happened",
              icon: Icons.bug_report,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            _buildAttachSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient.scale(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          PrimaryText("Support / Report a Problem", color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "Please complete all required fields";
            }
            return null;
          },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAttachSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrimaryText("Attach Screenshot (optional)"),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: pickFile,
          icon: const Icon(Icons.attachment, color: Colors.white),
          label: Text(
            selectedFile == null
                ? "Select File"
                : "File Selected: ${selectedFile!.name}",
            style: const TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }
}
