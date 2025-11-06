import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/constant.dart';

class OnboardingProgressIndicators extends StatelessWidget {
  final int currentIndex;
  final bool isDesktop;

  const OnboardingProgressIndicators({
    super.key,
    required this.currentIndex,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isDesktop
          ? const EdgeInsets.only(left: 20, right: 20, bottom: 24)
          : const EdgeInsets.only(bottom: 20),
      child: Row(
        children: List.generate(
          AppConstants.onboardingImages.length,
          (index) => CustomProgressIndicator(
            index,
            currentIndex: currentIndex,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
