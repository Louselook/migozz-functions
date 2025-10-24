import 'dart:async';
import 'package:flutter/widgets.dart';
import 'onboarding_model.dart';

class AppConstants {
  static const String appName = 'Migozz';

  /// Páginas compartidas entre mobile y web
  static const List<OnboardingData> onboardingPages = [
    OnboardingData(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Welcome',
      description:
          'It is a long established fact that a reader will be distracted by the readable content',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'Best social app to make new friends',
      description:
          'Integrate content from different social media platforms into one cohesive experience',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'Create, find and join your circle now',
      description:
          'The platform allows content creators to share your content in various, such as text, photos, and videos, and even repost content from other platforms!',
    ),
  ];

  /// Lista de imágenes para precarga
  static List<String> get onboardingImages =>
      onboardingPages.map((p) => p.imagePath).toList();

  /// Precache compartido
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
