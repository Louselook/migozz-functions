import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';
import 'onboarding_progress_indicators.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/color.dart';
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
    // Escala del texto basada en el ancho de pantalla
    final double titleSize = isDesktop
        ? (MediaQuery.of(context).size.width < 900 ? 32 : 40)
        : 28;
    final double textSize = isDesktop
        ? (MediaQuery.of(context).size.width < 900 ? 20 : 24)
        : 14;

    return Column(
      mainAxisAlignment: isDesktop
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) SizedBox(height: 5), // Spacer similar to mobile
        // Progress indicators
        if (isDesktop) ...[
          OnboardingProgressIndicators(
            currentIndex: currentPage,
            isDesktop: isDesktop,
          ),
          SizedBox(height: 20),
        ],

        // Título
        PrimaryText(
          data.titleKey.tr(),
          fontSize: titleSize,
          fontfamily: 'Inter',
          textAlign: TextAlign.start,
        ),

        SizedBox(height: 8),

        // Subtítulo (si existe)
        if (data.subTitleKey != null && data.subTitleKey!.isNotEmpty) ...[
          SecondaryText(
            data.subTitleKey!.tr(),
            textAlign: TextAlign.start,
            fontfamily: 'Inter',
            fontSize: textSize,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: 4), // Pequeño espacio entre subtítulo y descripción
        ],

        // Descripción
        SecondaryText(
          data.descriptionKey.tr(),
          textAlign: TextAlign.start,
          fontfamily: 'Inter',
          fontSize: textSize,
          color: AppColors.secondaryText.withValues(alpha: 0.53),
        ),

        if (!isDesktop) Spacer(),

        SizedBox(height: isDesktop ? 60 : 20),

        // Actions (Next / Skip / Get Started)
        OnboardingActions(
          controller: controller,
          lastPage: lastPage,
          isDesktop: isDesktop,
          screenWidth: MediaQuery.of(context).size.width,
        ),
      ],
    );
  }
}
