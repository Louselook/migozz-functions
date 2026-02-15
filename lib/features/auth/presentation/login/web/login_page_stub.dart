// lib/features/auth/presentation/login/web/login_page_stub.dart
// This is a stub file used when compiling for non-web platforms
// It prevents web-specific imports from being included in mobile builds

import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This should never be called on non-web platforms
    return const Scaffold(
      body: Center(
        child: Text('Web login page is not available on this platform'),
      ),
    );
  }
}

