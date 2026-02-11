import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingActions extends StatelessWidget {
  final PageController controller;
  final bool lastPage;
  final bool isDesktop;
  final double screenWidth;

  const OnboardingActions({
    super.key,
    required this.controller,
    required this.lastPage,
    required this.isDesktop,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final aspectRatio = screenHeight / screenWidth;
    final isVeryTallScreen = aspectRatio > 2.0;
    final isMobileWeb = !isDesktop && screenWidth < 500;

    if (lastPage) {
      return SizedBox(
        width: isDesktop ? null : double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            fixedSize: Size(
              screenWidth < 500 ? 180 : (screenWidth < 600 ? 200 : 260),
              isVeryTallScreen ? 36 : (screenWidth < 600 ? 40 : 50),
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
                    "onboarding.buttons.getStarted".tr(),
                    style: TextStyle(
                      fontSize: isVeryTallScreen
                          ? 14
                          : (screenWidth < 600 ? 18 : 24),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: isVeryTallScreen ? 14 : (screenWidth < 600 ? 16 : 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: isDesktop
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      children: [
        if (isDesktop) ...[
          // Desktop: Skip button on the left of Next button, grouped
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "onboarding.buttons.skip".tr(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(
                  alpha: 0.7,
                ), // Slightly dimmer for secondary action
              ),
            ),
          ),
          const SizedBox(width: 24), // Spacing between Skip and Next
        ],

        if (!isDesktop)
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobileWeb ? 12 : (screenWidth < 600 ? 16 : 24),
                vertical: isVeryTallScreen ? 4 : (screenWidth < 600 ? 8 : 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "onboarding.buttons.skip".tr(),
              style: TextStyle(
                fontSize: isVeryTallScreen ? 14 : (screenWidth < 600 ? 18 : 24),
                color: Colors.white,
              ),
            ),
          ),

        ElevatedButton(
          onPressed: () {
            if (controller.hasClients) {
              controller.nextPage(
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeInOutCubic,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            fixedSize: Size(
              isMobileWeb ? 100 : (screenWidth < 600 ? 120 : 160),
              isVeryTallScreen ? 38 : (screenWidth < 600 ? 44 : 56),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounder corners
            ),
            elevation: 8, // Add some shadow
            shadowColor: const Color(0xFFD43AB6).withValues(alpha: 0.5),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "onboarding.buttons.next".tr(),
                    style: TextStyle(
                      fontSize: isVeryTallScreen
                          ? 14
                          : (screenWidth < 600 ? 16 : 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded, // Rounded arrow
                    color: Colors.white,
                    size: isVeryTallScreen ? 16 : (screenWidth < 600 ? 18 : 20),
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
