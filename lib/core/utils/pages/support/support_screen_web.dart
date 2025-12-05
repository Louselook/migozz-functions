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
                  ? buildTwoColumnLayout()
                  : buildSingleColumnLayout(),
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

  Widget buildTwoColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: buildFormCard()),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: SupportInfoCard()),
        ],
      ),
    );
  }

  Widget buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          buildFormCard(),
          const SizedBox(height: 20),
          SupportInfoCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildFormCard() {
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
            buildResponsiveHeader(context),
            const SizedBox(height: 20),
            buildTextField(
              controller: _nameCtrl,
              label: "Your Name",
              placeholder: "Enter your name",
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            buildTextField(
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
            buildTextField(
              controller: _messageCtrl,
              label: "Describe the Issue",
              placeholder: "Explain what happened",
              icon: Icons.bug_report,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            buildAttachSection(),
          ],
        ),
      ),
    );
  }

  Widget buildResponsiveHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 12),

          // En móvil, el texto se adapta automático
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: isMobile ? BoxFit.scaleDown : BoxFit.none,
              child: PrimaryText(
                "Support / Report a Problem",
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
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

  Widget buildAttachSection() {
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

  Widget buildInfoCard() {
    // Reusable small widgets
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
        );

    Widget paragraph(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 820),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading("Need help? You’re in the right place"),
              paragraph(
                  "If you are experiencing issues or need assistance with the app, our team is available to help you resolve technical problems, account issues, and general questions about the platform."),
              heading("Contact Email"),
              paragraph("If you prefer to contact us by email, write to:"),
              Row(
                children: [
                  const Icon(Icons.mail, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => html.window.open('mailto:migozzoficial@gmail.com', '_self'),
                    child: Text('migozzoficial@gmail.com',
                        style: const TextStyle(
                            color: Colors.white, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class SupportInfoCard extends StatelessWidget {
  const SupportInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrimaryText("Support Information", color: Colors.white),
            const SizedBox(height: 20),

            _sectionTitle("If you are experiencing issues…"),
            _text("""
              If you are experiencing issues or need assistance with the app, you are in the right place. Our team is available to help you resolve technical problems, account issues, and general questions about the platform.

              You can use the form on the left to contact us directly.
              """),

            _sectionTitle("📩 Contact Email"),
            _text("""
              If you prefer contacting us through email, write to:

              migozzoficial@gmail.com

              We typically respond within 48 business hours.
              """),

            _sectionTitle("🛠 How to Report a Problem"),
            _text("""
              When reporting an issue, please include:

              • Your name
              • Your email
              • A detailed description of the problem
              • Steps to reproduce the issue
              • Device model and operating system
              • A screenshot (optional but helpful)

              This information helps us resolve your issue faster.
              """),

            _sectionTitle("❓ Frequently Asked Questions (FAQ)"),
            _text("""
              1. What is Migozz?
              Migozz is an AI-powered platform that connects your social media profiles, analyzes your digital presence, and helps you build and manage your online community.

              2. Is my personal information safe?
              Yes. We use secure technologies such as Firebase and Google Cloud to protect your data. You can review our Privacy Policy for full details.

              3. Why does the app request access to my camera?
              The camera is used only to allow you to take photos for your profile or to generate AI-based content. You may deny access at any time.

              4. How can I delete my account and data?
              You may request account deletion at any time by contacting migozzoficial@gmail.com. Once deleted, your data cannot be recovered.

              5. What should I do if the app crashes or does not load?
              Please provide your device information, app version, and steps leading to the crash using the form.
              """),

            _sectionTitle("🔗 Useful Links"),
            _text("""
              Terms of Service: https://migozz-e2a21.web.app/terms-privacy
              Privacy Policy: https://migozz-e2a21.web.app/terms-privacy
              Home Page: https://migozz-e2a21.web.app/
              """),

            const SizedBox(height: 10),
            PrimaryText(
              "Thank you for using Migozz!",
              color: Colors.white,
            ),
            const SizedBox(height: 5),
            _text("""
              Our goal is to provide the best possible experience. If you need further assistance, feel free to reach out through the support form or email.
              """),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PrimaryText(text, color: Colors.white),
    );
  }

  Widget _text(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SecondaryText(
        text,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}

