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

              const SizedBox(width: 56),

              // Contenido (texto y botones)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxWidth: 500),
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
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parte superior → contenido (40%)
              Expanded(
                flex: screenHeight < 800 ? 4 : 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
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

              // Parte inferior → imagen (60%)
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OnboardingImage(
                    data: data,
                    isDesktop: false,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    delta: delta,
                    t: t,
                  ),
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
