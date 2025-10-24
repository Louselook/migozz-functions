// lib/features/auth/presentation/onboarding/onboarding_entry.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'mobile/onboarding_screen.dart' as mobile;
import 'web/onboarding_page.dart' as web;

/// Devuelve la UI correcta según la plataforma.
/// Las pantallas ya deben envolver su UI con onboardingWrapper si corresponde.
class OnboardingEntry extends StatelessWidget {
  const OnboardingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isWeb) {
      return const web.OnboardingPage();
    }
    // móvil / desktop -> usar la UI mobile (si quieres un desktop distinto, añade lógica)
    return const mobile.OnboardingScreen();
  }
}
