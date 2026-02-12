import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/onboarding_model.dart';
import 'cached_onboarding_image.dart';

class OnboardingImage extends StatelessWidget {
  final OnboardingData data;
  final bool isDesktop;
  final double screenWidth;
  final double screenHeight;
  final double delta;
  final double t;

  const OnboardingImage({
    super.key,
    required this.data,
    required this.isDesktop,
    required this.screenWidth,
    required this.screenHeight,
    required this.delta,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      final imageWidth = screenWidth * 0.5;
      final imageParallaxX = delta * 20;
      final imageScale = 0.97 + 0.03 * t;

      return SizedBox(
        width: imageWidth,
        height: screenHeight,
        child: Transform.translate(
          offset: Offset(imageParallaxX, 0),
          child: Transform.scale(
            scale: imageScale,
            alignment: Alignment.center,
            child: CachedOnboardingImage(
              imagePath: data.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Stack(
          children: [
            // Imagen principal - ocupa todo el espacio
            Positioned.fill(
              child: CachedOnboardingImage(
                imagePath: data.imagePath,
                fit: BoxFit.cover,
                scale: 1,
                alignment: Alignment.bottomCenter,
              ),
            ),
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
      );
    }
  }
}
