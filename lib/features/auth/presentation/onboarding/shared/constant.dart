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
    for (final path in onboardingImages) {
      final provider = AssetImage(path);
      if (context != null) {
        await precacheImage(provider, context);
      } else {
        final config = const ImageConfiguration();
        final completer = Completer<void>();
        final stream = provider.resolve(config);
        final listener = ImageStreamListener(
          (image, _) => completer.complete(),
          onError: (_, __) => completer.complete(),
        );
        stream.addListener(listener);
        await completer.future;
        stream.removeListener(listener);
      }
    }
  }
}