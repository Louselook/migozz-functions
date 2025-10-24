// lib/features/auth/presentation/login/web/login_page.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/features/auth/presentation/login/shared/login_wrapper.dart';
import 'package:migozz_app/features/auth/presentation/login/web/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Logo(width: 250, height: 250),
                      const SizedBox(height: 20),
                      // Título
                      const Text(
                        'Welcome to Migozz!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      const Text(
                        'Connect your Community',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              const SizedBox(width: 365, child: LoginForm()),
              const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }
}
