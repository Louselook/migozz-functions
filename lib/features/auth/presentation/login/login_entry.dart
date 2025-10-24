// lib/features/auth/presentation/login/login_entry.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'mobile/login_screen.dart' as mobile;
import 'web/login_page.dart' as web;

/// Devuelve la UI correcta según la plataforma.
/// Las pantallas ya deben envolver su UI con LoginWrapper si corresponde.
class LoginEntry extends StatelessWidget {
  const LoginEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isWeb) {
      return const web.LoginPage();
    }
    // móvil / desktop -> usar la UI mobile (si quieres un desktop distinto, añade lógica)
    return const mobile.LoginScreen();
  }
}
