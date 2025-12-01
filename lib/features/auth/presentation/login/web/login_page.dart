import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/features/auth/presentation/login/shared/login_wrapper.dart';
import 'package:migozz_app/features/auth/presentation/login/web/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Widget _buildSupportHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: () => context.go("/support"),
        child: const Text(
          "If you have any errors, please report it here",
          style: TextStyle(
            color: Colors.pinkAccent,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  

  // Sección del logo + textos, reutilizada en mobile/desktop
  Widget _buildLogoSection(double logoSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(width: logoSize, height: logoSize),
        const SizedBox(height: 20),
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
        const Text(
          'Connect your Community',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Layout para pantallas móviles (ancho pequeño)
  Widget _buildMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoSize = width * 0.35; // tamaño del logo relativo al ancho

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoSection(logoSize.clamp(120, 180)),
          const SizedBox(height: 40),
          const LoginForm(),
          _buildSupportHint(context)
        ],
      ),
    );
  }

  // Layout para pantallas grandes (web / tablet / desktop)
  Widget _buildDesktopLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ancho del formulario limitado para que no se vea gigante
    final formWidth = (width * 0.28).clamp(340.0, 420.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLogoSection(250),
            ),
          ),
          const SizedBox(width: 32),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: formWidth, child: const LoginForm()),
              _buildSupportHint(context), 
            ],
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                child: isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
              ),
            );
          },
        ),
      ),
    );
  }
}
