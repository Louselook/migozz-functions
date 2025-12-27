import 'dart:async';
import 'package:flutter/widgets.dart';
// import 'package:easy_localization/easy_localization.dart';
import 'onboarding_model.dart';

class AppConstants {
  static const String appName = 'Migozz';

  static const List<OnboardingData> onboardingPages = [
    OnboardingData(
      imagePath: "assets/images/onboarding_1.webp",
      titleKey: "onboarding.titles.onboardingTitle1",
      subTitleKey: "onboarding.subtitles.onboardingSubtitle1",
      descriptionKey: "onboarding.descriptions.onboardingDescription1",
    ),
    OnboardingData(
      imagePath: "assets/images/onboarding_2.webp",
      titleKey: "onboarding.titles.onboardingTitle2",
      descriptionKey: "onboarding.descriptions.onboardingDescription2",
    ),
    OnboardingData(
      imagePath: "assets/images/onboarding_3.webp",
      titleKey: "onboarding.titles.onboardingTitle3",
      descriptionKey: "onboarding.descriptions.onboardingDescription3",
    ),
  ];

  static List<String> get onboardingImages =>
      onboardingPages.map((p) => p.imagePath).toList();

  static Future<void> precacheOnboardingImages([BuildContext? context]) async {
    if (context == null) return;

    // Precarga todas las imágenes en paralelo con manejo de errores
    await Future.wait(
      onboardingImages.map((path) async {
        try {
          final provider = AssetImage(path);
          await precacheImage(
            provider,
            context,
            onError: (exception, stackTrace) {
              // Log del error pero continúa cargando otras imágenes
              debugPrint('Error precaching image $path: $exception');
            },
          );
        } catch (e) {
          debugPrint('Failed to precache $path: $e');
        }
      }),
    );
  }
}
