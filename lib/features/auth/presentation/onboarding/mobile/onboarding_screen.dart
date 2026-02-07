import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/constant.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // mantengo la propiedad gradient como estaba en tu código original
  get gradient => null;

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
    // Usa ScreenUtil valores escalados para paddings/medidas
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Indicadores de progreso
            Padding(
              padding: EdgeInsets.only(top: 10, left: 20.w, right: 20.w),
              child: Row(
                spacing: 5,
                children: List.generate(
                  AppConstants.onboardingImages.length,
                  (index) => CustomProgressIndicator(
                    index,
                    currentIndex: _currentPage,
                    borderRadius: BorderRadius.circular(4.r),
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
                itemCount: AppConstants.onboardingImages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                    context,
                    AppConstants.onboardingPages[index],
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context,
    OnboardingData data,
    int index,
  ) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenHeight <= 800;

    return Column(
      children: [
        Expanded(
          flex: isSmallScreen ? 3 : 4,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 15,
              children: [
                PrimaryText(
                  data.titleKey.tr(),
                  fontSize: isSmallScreen ? 20 : 24,
                  fontfamily: 'Inter',
                  width: index == 1 ? (screenWidth * 60 / 100) : null,
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    data.subTitleKey != null
                        ? SecondaryText(
                            data.subTitleKey != null
                                ? data.subTitleKey!.tr()
                                : "",
                            textAlign: TextAlign.start,
                            fontfamily: 'Inter',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          )
                        : SizedBox.shrink(),

                    Container(
                      constraints: BoxConstraints(
                        minHeight: 60
                      ),
                      child: SecondaryText(
                        data.descriptionKey.tr(),
                        textAlign: TextAlign.start,
                        fontfamily: 'Inter',
                        fontSize: isSmallScreen ? 14.sp : 15.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                _currentPage == AppConstants.onboardingImages.length - 1
                    ? SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: () => context.go('/login'),
                          child: TextWithIcon(
                            "onboarding.buttons.getStarted".tr(),
                            icon: Icons.arrow_forward_ios_rounded,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ButtonText(
                            text: "onboarding.buttons.skip".tr(),
                            onPressed: () => context.go('/login'),
                          ),
                          SizedBox(
                            width: 110.w,
                            child: GradientButton(
                              child: TextWithIcon(
                                "onboarding.buttons.next".tr(),
                                spacing: 20.w,
                                icon: Icons.arrow_forward_ios_rounded,
                              ),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),

        // Parte inferior → 50%
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.verticalOnboarding,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
                child: Stack(
                  children: [
                    // Imagen principal siempre abajo y centrada
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        child: Image.asset(
                          data.imagePath,
                          key: ValueKey<String>(data.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          gaplessPlayback: true,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) {
                                  return child;
                                }
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Error loading image ${data.imagePath}: $error',
                            );
                            return Container(
                              color: Colors.grey.withValues(alpha: 0.3),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50.r,
                                  color: Colors.white54,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Efecto radial
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomRight,
                            radius: 0.6,
                            colors: [
                              AppColors.radialEffect,
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
        ),
      ],
    );
  }
}
