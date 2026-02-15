// lib/features/auth/presentation/login/login_entry.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'mobile/login_screen.dart' as mobile;
import 'web/login_page_stub.dart' if (dart.library.html) 'web/login_page.dart' as web;

/// Devuelve la UI correcta según la plataforma.
/// Las pantallas ya deben envolver su UI con LoginWrapper si corresponde.
class LoginEntry extends StatelessWidget {
  const LoginEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const web.LoginPage();
    }
    // móvil / desktop -> usar la UI mobile (si quieres un desktop distinto, añade lógica)
    return const mobile.LoginScreen();
  }
}
