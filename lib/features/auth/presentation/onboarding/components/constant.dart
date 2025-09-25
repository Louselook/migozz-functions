import 'dart:async';

import 'package:flutter/widgets.dart';

class AppConstants {
  static const String appName = 'Migozz';

  // Onboarding texts
  static const List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: 'Welcome',
      description:
          'It is a long established fact that a reader will be distracted by the readable content',
    ),
    OnboardingData(
      title: 'Best social app to make new friends',
      description:
          'Integrate content from different social media platforms into one cohesive experience',
    ),
    OnboardingData(
      title: 'Create, find and join your circle now',
      description:
          'The platform allows content creators to share your content in various, such as text, photos, and videos, and even repost content from other platforms!',
    ),
  ];

  // Nueva lista de imágenes
  static const List<String> onboardingImages = [
    'assets/images/onboarding_1.png',
    'assets/images/onboarding_2.png',
    'assets/images/onboarding_3.png',
    'assets/icons/Migozz@300x.png',
  ];

  // Helper para precargar imágenes
  static Future<void> precacheOnboardingImages() async {
    for (final path in onboardingImages) {
      final imageProvider = AssetImage(path);
      final config = const ImageConfiguration(); // no necesita contexto
      final completer = Completer<void>();

      final stream = imageProvider.resolve(config);
      final listener = ImageStreamListener(
        (image, synchronousCall) => completer.complete(),
        onError: (error, stackTrace) => completer.complete(),
      );

      stream.addListener(listener);
      await completer.future;
      stream.removeListener(listener);
    }
  }
}

class OnboardingData {
  final String title;
  final String description;

  const OnboardingData({required this.title, required this.description});
}
