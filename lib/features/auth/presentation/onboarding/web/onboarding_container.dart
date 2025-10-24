import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/constant.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';

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
    final imageWidth = screenWidth * 0.5;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : currentPage.toDouble();

        final delta = (pageIndex - page);
        final tRaw = (1 - delta.abs()).clamp(0.0, 1.0);
        final t = Curves.easeInOutCubicEmphasized.transform(tRaw);

        final imageParallaxX = delta * 20;
        final imageScale = 0.97 + 0.03 * t;
        final contentOpacity = (0.65 + 0.35 * t).clamp(0.0, 1.0);
        final contentTranslateY = (1 - t) * 12;

        return Row(
          children: [
            // imagen con fondo degradado
            Container(
              width: imageWidth,
              height: screenHeight,
              decoration: BoxDecoration(
                gradient: AppColors.verticalOnboarding,
              ),
              child: Transform.translate(
                offset: Offset(imageParallaxX, 0),
                child: Transform.scale(
                  scale: imageScale,
                  alignment: Alignment.center,
                  child: Image.asset(
                    data.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 56),

            // (texto y botones)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                constraints: const BoxConstraints(maxWidth: 500),
                child: Opacity(
                  opacity: contentOpacity,
                  child: Transform.translate(
                    offset: Offset(0, contentTranslateY),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                          child: Row(
                            children: List.generate(
                              AppConstants.onboardingPages.length,
                              (index) => CustomProgressIndicator(
                                index,
                                currentIndex: currentPage,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          data.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth < 600
                                ? 24
                                : (screenWidth < 900 ? 32 : 40),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          data.description,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 600
                                ? 16
                                : (screenWidth < 900 ? 20 : 24),
                          ),
                        ),

                        SizedBox(height: screenWidth < 600 ? 40 : 107),

                        Row(
                          children: [
                            if (!lastPage)
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth < 600 ? 16 : 50,
                                    vertical: screenWidth < 600 ? 8 : 23,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Skip",
                                  style: TextStyle(
                                    fontSize: screenWidth < 600 ? 18 : 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: () {
                                if (lastPage) {
                                  context.go('/login');
                                } else {
                                  controller.nextPage(
                                    duration: const Duration(milliseconds: 460),
                                    curve: Curves.easeInOutCubic,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                fixedSize: Size(
                                  lastPage
                                      ? (screenWidth < 600 ? 200 : 260)
                                      : (screenWidth < 600 ? 90 : 116),
                                  screenWidth < 600 ? 40 : 50,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF89A44),
                                      Color(0xFFD43AB6),
                                      Color(0xFF9321BD),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lastPage ? 'Get Started' : 'Next',
                                        style: TextStyle(
                                          fontSize: screenWidth < 600 ? 18 : 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: screenWidth < 600 ? 16 : 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
