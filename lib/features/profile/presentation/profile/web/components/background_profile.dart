import 'package:flutter/material.dart';

class BackgroundProfile extends StatelessWidget {
  final Widget child;

  /// Qué tanto puede colapsar el header (0.5 = se detiene a mitad de pantalla)
  final double minHeaderFraction;

  const BackgroundProfile({
    super.key,
    required this.child,
    this.minHeaderFraction = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    // Responsive: Alturas base
    final bottomGradientHeight = isSmallScreen
        ? size.height * 0.25
        : isMediumScreen
        ? size.height * 0.22
        : size.height * 0.20;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo base negro
        Container(color: Colors.black),

        // Imagen de perfil de fondo (opcional, se puede cambiar por usuario)
        Positioned.fill(
          child: Image.asset(
            'assets/image/ImgPefil.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.black);
            },
          ),
        ),

        // Overlay oscuro para mejor legibilidad
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),

        // Tinte morado superior izq (radial)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.9), // arriba-izquierda
                radius: 0.4,
                colors: [
                  const Color(0xFF9D43A5).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),

        // Gradiente dorado inferior, suave
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomGradientHeight * 1.6,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, 1.0),
                  radius: 1.5,
                  colors: [
                    const Color(0xFFF3C623).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.8],
                ),
              ),
            ),
          ),
        ),

        // Overlays por encima (IA, rail, bottom nav, etc.)
        child,
      ],
    );
  }
}
