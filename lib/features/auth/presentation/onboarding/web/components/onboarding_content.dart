import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';
import 'onboarding_progress_indicators.dart';
import 'onboarding_actions.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingData data;
  final PageController controller;
  final bool lastPage;
  final int currentPage;
  final int totalPages;
  final int pageIndex;
  final bool isDesktop;

  const OnboardingContent({
    super.key,
    required this.data,
    required this.controller,
    this.lastPage = false,
    required this.currentPage,
    required this.totalPages,
    required this.pageIndex,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: isDesktop
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicators
        OnboardingProgressIndicators(
          currentIndex: currentPage,
          isDesktop: isDesktop,
        ),

        // Título
        Padding(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 0)
              : EdgeInsets.zero,
          child: Text(
            data.titleKey.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 600 ? 24 : (screenWidth < 900 ? 32 : 40),
            ),
          ),
        ),

        SizedBox(height: screenWidth < 600 ? 8 : 12),

        // Descripción
        Padding(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 0)
              : EdgeInsets.zero,
          child: Text(
            data.descriptionKey.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: screenWidth < 600 ? 16 : (screenWidth < 900 ? 20 : 24),
            ),
          ),
        ),

        if (!isDesktop) const Spacer(),

        SizedBox(height: isDesktop ? (screenWidth < 600 ? 40 : 107) : 20),

        // Actions (Next / Skip / Get Started)
        OnboardingActions(
          controller: controller,
          lastPage: lastPage,
          isDesktop: isDesktop,
          screenWidth: screenWidth,
        ),
      ],
    );
  }
}
