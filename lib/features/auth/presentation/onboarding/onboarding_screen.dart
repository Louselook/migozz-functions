import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/components/constant.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppConstants.precacheOnboardingImages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Indicadores de progreso
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
            child: Row(
              children: List.generate(
                AppConstants.onboardingPages.length,
                (index) => CustomProgressIndicator(
                  index,
                  currentIndex: _currentPage,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Contenido de páginas
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: AppConstants.onboardingPages.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(
                  context,
                  AppConstants.onboardingPages[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, OnboardingData data) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parte superior → 40%
        Expanded(
          flex: screenHeight < 800 ? 4 : 3, // para no chocar componetes
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                PrimaryText(data.title),
                const SizedBox(height: 8),
                SecondaryText(
                  data.description,
                  textAlign: TextAlign.start,
                  color: AppColors.secondaryText.withValues(alpha: 0.53),
                ),
                const Spacer(),

                // Botones
                _currentPage == AppConstants.onboardingPages.length - 1
                    ? SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: () => context.go('/login'),
                          child: const TextWithIcon(
                            "Get Started",
                            icon: Icons.arrow_forward_ios_rounded,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ButtonText(
                            text: 'Skip',
                            onPressed: () => context.go('/login'),
                          ),
                          GradientButton(
                            child: const TextWithIcon(
                              "Next",
                              spacing: 20,
                              icon: Icons.arrow_forward_ios_rounded,
                            ),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),

        // Parte inferior → 60%
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Stack(
                  children: [
                    // Imagen principal siempre abajo y centrada
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          scale: screenHeight < 800 ? 1.5 : 1,
                          data.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            //issamu382@gmail.com
                    // Efecto radial
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomRight,
                            radius: 0.6,
                            colors: [AppColors.radialEffect, Colors.transparent],
                            stops: [0, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
