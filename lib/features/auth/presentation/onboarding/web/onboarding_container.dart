import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';
import 'components/onboarding_image.dart';
import 'components/onboarding_content.dart';

class OnboardingContainer extends StatelessWidget {
  final OnboardingData data;
  final PageController controller;
  final bool lastPage;
  final int currentPage;
  final int totalPages;
  final int pageIndex;

  const OnboardingContainer({
    super.key,
    required this.data,
    required this.controller,
    this.lastPage = false,
    required this.currentPage,
    required this.totalPages,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth >= 900;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : currentPage.toDouble();

        final delta = (pageIndex - page);
        final tRaw = (1 - delta.abs()).clamp(0.0, 1.0);
        final t = Curves.easeInOutCubicEmphasized.transform(tRaw);

        final contentOpacity = (0.65 + 0.35 * t).clamp(0.0, 1.0);
        final contentTranslateY = (1 - t) * 12;

        if (isDesktop) {
          return Row(
            children: [
              // Imagen (componente)
              OnboardingImage(
                data: data,
                isDesktop: true,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                delta: delta,
                t: t,
              ),

              // Contenido (texto y botones)
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Opacity(
                      opacity: contentOpacity,
                      child: Transform.translate(
                        offset: Offset(0, contentTranslateY),
                        child: OnboardingContent(
                          data: data,
                          controller: controller,
                          lastPage: lastPage,
                          currentPage: currentPage,
                          totalPages: totalPages,
                          pageIndex: pageIndex,
                          isDesktop: isDesktop,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Calcular alturas fijas basadas en el tamaño de pantalla
          final aspectRatio = screenHeight / screenWidth;
          final isVeryTallScreen =
              aspectRatio > 2.0; // Pantallas tipo S25 Ultra

          // Alturas fijas para mantener consistencia entre páginas
          // Aumentadas para dar más espacio al contenido
          final contentHeight = isVeryTallScreen
              ? screenHeight * 0.32
              : (screenHeight < 800
                    ? screenHeight * 0.36
                    : screenHeight * 0.34);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parte superior → contenido con altura fija
              SizedBox(
                height: contentHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: isVeryTallScreen ? 12 : 20,
                    bottom: 8,
                  ),
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Transform.translate(
                      offset: Offset(0, contentTranslateY),
                      child: OnboardingContent(
                        data: data,
                        controller: controller,
                        lastPage: lastPage,
                        currentPage: currentPage,
                        totalPages: totalPages,
                        pageIndex: pageIndex,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
                ),
              ),

              // Parte inferior → imagen ocupa el resto
              Expanded(
                child: OnboardingImage(
                  data: data,
                  isDesktop: false,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  delta: delta,
                  t: t,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // _buildContent moved to components/onboarding_content.dart
}
