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
    if (lastPage) {
      return SizedBox(
        width: isDesktop ? null : double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            fixedSize: Size(
              screenWidth < 600 ? 200 : 260,
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
                    'Get Started',
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
      );
    }

    return Row(
      mainAxisAlignment: isDesktop
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      children: [
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
              screenWidth < 600 ? 90 : 116,
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
                    'Next',
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
    );
  }
}
