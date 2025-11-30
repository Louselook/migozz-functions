// ignore: deprecated_member_use, avoid_web_libraries_in_flutter, Solo para Web (upload files)
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  html.File? selectedFile;

  Future<void> pickFile() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file != null) {
        setState(() => selectedFile = file);
      }
    });
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
            /// HEADER
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryText("support.header".tr()),
                  ),
                ],
              ),
            ),

            /// CONTENIDO
            Expanded(
              child: isDesktop || isTablet
                  ? _buildDesktopLayout()
                  : _buildMobileLayout(),
            ),

            /// BOTÓN ENVIAR
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
                      SecondaryText("support.button.send".tr()),
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

  // DESKTOP/TABLET COLUMN
  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: _buildFormCard(),
      ),
    );
  }

  // MOBILE
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildFormCard(),
    );
  }

  // MAIN CARD
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
              label: "support.form.name.label".tr(),
              placeholder: "support.form.name.placeholder".tr(),
              icon: Icons.person,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _emailCtrl,
              label: "support.form.email.label".tr(),
              placeholder: "support.form.email.placeholder".tr(),
              icon: Icons.email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "support.snackbar.validationError".tr();
                }
                if (!value.contains('@')) {
                  return "support.snackbar.invalidEmail".tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _messageCtrl,
              label: "support.form.message.label".tr(),
              placeholder: "support.form.message.placeholder".tr(),
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
          PrimaryText("support.header".tr(), color: Colors.white),
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
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "support.snackbar.validationError".tr();
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
        PrimaryText("support.form.attachment.title".tr()),
        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: pickFile,
          icon: const Icon(Icons.attachment, color: Colors.white),
          label: Text(
            selectedFile == null
                ? "support.form.attachment.button".tr()
                : "${"support.form.attachment.selected".tr()}: ${selectedFile!.name}",
            style: const TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    debugPrint("Nombre: ${_nameCtrl.text}");
    debugPrint("Correo: ${_emailCtrl.text}");
    debugPrint("Mensaje: ${_messageCtrl.text}");
    debugPrint("Archivo: ${selectedFile?.name}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("support.snackbar.success".tr())),
    );
  }
}
