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
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = screenSize.height / screenSize.width;
    final isVeryTallScreen = aspectRatio > 2.0; // Pantallas tipo S25 Ultra
    final isMobileWeb = !isDesktop && screenSize.width < 500;

    // Escala del texto basada en el ancho de pantalla - más compacto para móvil web
    final double titleSize = isDesktop
        ? (screenSize.width < 900 ? 32 : 40)
        : (isVeryTallScreen ? 22 : (isMobileWeb ? 24 : 28));
    final double textSize = isDesktop
        ? (screenSize.width < 900 ? 16 : 18)
        : (isVeryTallScreen ? 12 : (isMobileWeb ? 13 : 14));
    final double spacing = isVeryTallScreen ? 6 : (isMobileWeb ? 8 : 16);

    // Para móvil: layout con posiciones fijas
    if (!isDesktop) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área de texto con scroll si es necesario
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  PrimaryText(
                    data.titleKey.tr(),
                    fontSize: titleSize,
                    fontfamily: 'Inter',
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: spacing),
                  // Subtítulo (si existe)
                  if (data.subTitleKey != null &&
                      data.subTitleKey!.isNotEmpty) ...[
                    SecondaryText(
                      data.subTitleKey!.tr(),
                      textAlign: TextAlign.start,
                      fontfamily: 'Inter',
                      fontSize: textSize,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(height: isVeryTallScreen ? 4 : 8),
                  ],
                  // Descripción
                  SecondaryText(
                    data.descriptionKey.tr(),
                    textAlign: TextAlign.start,
                    fontfamily: 'Inter',
                    fontSize: textSize,
                    color: AppColors.secondaryText.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          // Botones siempre en la parte inferior
          Padding(
            padding: EdgeInsets.only(top: isVeryTallScreen ? 8 : 12),
            child: OnboardingActions(
              controller: controller,
              lastPage: lastPage,
              isDesktop: isDesktop,
              screenWidth: screenSize.width,
            ),
          ),
        ],
      );
    }

    // Desktop: layout original
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicators
        OnboardingProgressIndicators(
          currentIndex: currentPage,
          isDesktop: isDesktop,
        ),
        SizedBox(height: 32),

        // Título
        PrimaryText(
          data.titleKey.tr(),
          fontSize: titleSize,
          fontfamily: 'Inter',
          textAlign: TextAlign.start,
        ),

        SizedBox(height: spacing),
        // Subtítulo (si existe)
        if (data.subTitleKey != null && data.subTitleKey!.isNotEmpty) ...[
          SecondaryText(
            data.subTitleKey!.tr(),
            textAlign: TextAlign.start,
            fontfamily: 'Inter',
            fontSize: textSize,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: isVeryTallScreen ? 4 : 8),
        ],

        // Descripción
        SecondaryText(
          data.descriptionKey.tr(),
          textAlign: TextAlign.start,
          fontfamily: 'Inter',
          fontSize: textSize,
          color: AppColors.secondaryText.withValues(alpha: 0.7),
        ),

        SizedBox(height: 48),
        // Actions
        OnboardingActions(
          controller: controller,
          lastPage: lastPage,
          isDesktop: isDesktop,
          screenWidth: screenSize.width,
        ),
      ],
    );
  }
}
