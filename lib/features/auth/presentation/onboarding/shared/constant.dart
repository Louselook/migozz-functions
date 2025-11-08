import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'onboarding_model.dart';

class AppConstants {
  static const String appName = 'Migozz';

  /// Getter para obtener las páginas según el idioma actual
  static List<OnboardingData> get onboardingPages => [
    OnboardingData(
      imagePath: "assets/images/onboarding_1.webp",
      title: "onboarding.titles.onboardingTitle1".tr(),
      description: "onboarding.descriptions.onboardingDescription1".tr(),
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_2.webp',
      title: "onboarding.titles.onboardingTitle2".tr(),
      description: "onboarding.descriptions.onboardingDescription2".tr(),
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_3.webp',
      title: "onboarding.titles.onboardingTitle3".tr(),
      description: "onboarding.descriptions.onboardingDescription3".tr(),
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
