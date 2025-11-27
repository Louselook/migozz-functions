import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

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
            // Header
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
                    child: PrimaryText('termsPrivacy.header'.tr()),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isDesktop || isTablet
                  ? _buildTwoColumnLayout()
                  : _buildSingleColumnLayout(),
            ),

            // Back to Login Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GradientButton(
                  width: double.infinity,
                  radius: 19,
                  onPressed: () => context.go('/login'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      SecondaryText("termsPrivacy.button.backToLogin".tr()),
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

  // Layout para desktop/tablet (2 columnas)
  Widget _buildTwoColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Términos de Servicio
          Expanded(child: _TermsSection(isMobile: false)),
          const SizedBox(width: 20),
          // Política de Privacidad
          Expanded(child: _PrivacySection(isMobile: false)),
        ],
      ),
    );
  }

  // Layout para móvil (scroll vertical)
  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _TermsSection(isMobile: true),
          const SizedBox(height: 30),
          _PrivacySection(isMobile: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Sección de Términos de Servicio
class _TermsSection extends StatelessWidget {
  final bool isMobile;

  const _TermsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient.scale(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'termsPrivacy.terms.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable (o no, dependiendo de isMobile)
          if (isMobile)
            _buildMobileContent(context)
          else
            Expanded(child: _buildDesktopContent(context)),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildContent(context),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(context),
        const SizedBox(height: 20),
        _buildSection(
          'termsPrivacy.terms.section1.title'.tr(),
          'termsPrivacy.terms.section1.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section2.title'.tr(),
          'termsPrivacy.terms.section2.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section3.title'.tr(),
          'termsPrivacy.terms.section3.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section4.title'.tr(),
          'termsPrivacy.terms.section4.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section5.title'.tr(),
          'termsPrivacy.terms.section5.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section6.title'.tr(),
          'termsPrivacy.terms.section6.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section7.title'.tr(),
          'termsPrivacy.terms.section7.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section8.title'.tr(),
          'termsPrivacy.terms.section8.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.terms.section9.title'.tr(),
          'termsPrivacy.terms.section9.content'.tr(),
        ),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Text(
      'termsPrivacy.terms.intro'.tr(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Sección de Política de Privacidad
class _PrivacySection extends StatelessWidget {
  final bool isMobile;

  const _PrivacySection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient.scale(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'termsPrivacy.privacy.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable (o no, dependiendo de isMobile)
          if (isMobile)
            _buildMobileContent(context)
          else
            Expanded(child: _buildDesktopContent(context)),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildContent(context),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(context),
        const SizedBox(height: 20),
        _buildSection(
          'termsPrivacy.privacy.section1.title'.tr(),
          'termsPrivacy.privacy.section1.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section2.title'.tr(),
          'termsPrivacy.privacy.section2.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section3.title'.tr(),
          'termsPrivacy.privacy.section3.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section4.title'.tr(),
          'termsPrivacy.privacy.section4.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section5.title'.tr(),
          'termsPrivacy.privacy.section5.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section6.title'.tr(),
          'termsPrivacy.privacy.section6.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section7.title'.tr(),
          'termsPrivacy.privacy.section7.content'.tr(),
        ),
        _buildSection(
          'termsPrivacy.privacy.section8.title'.tr(),
          'termsPrivacy.privacy.section8.content'.tr(),
        ),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Text(
      'termsPrivacy.privacy.intro'.tr(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
