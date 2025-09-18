import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/login_screen.dart';
import 'package:migozz_app/features/onboarding/components/constant.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Progress indicators
          Container(
            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
            child: Row(
              children: List.generate(
                3,
                (index) => CustomProgressIndicator(
                  index,
                  currentIndex: _currentPage,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Page content - Ahora ocupa el resto del espacio disponible
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
                  AppConstants.onboardingPages[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 230,
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
                          onPressed: () {
                            // Modificar avegacion
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
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
                            onPressed: () {
                              // Modificar avegacion
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
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
        Expanded(
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
                  // Imagen principal
                  Positioned.fill(
                    child: Align(
                      alignment: _currentPage == 1
                          ? Alignment.centerRight
                          : Alignment.center,
                      child: Image.asset(
                        'assets/images/onboarding_${_currentPage + 1}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Efecto de brillo radial
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.bottomRight,
                          radius: 0.6,
                          colors: [
                            AppColors.radialEffect, // Rojo con opacidad
                            Colors.transparent,
                          ],
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
      ],
    );
  }
}
