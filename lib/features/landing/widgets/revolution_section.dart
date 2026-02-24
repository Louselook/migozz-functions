import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Revolution section — "WELCOME TO THE REVOLUTION" with decorative vectors
class RevolutionSection extends StatelessWidget {
  const RevolutionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
      child: Container(
        // Dark overlay
        color: Colors.black.withValues(alpha: 0.2),
        child: Stack(
          children: [
            // Decorative MigozzVector images scattered in background
            ..._buildDecorativeVectors(isMobile),
            // Main content
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 60 : 80,
                horizontal: isMobile ? 16 : 32,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title 1 — Bebas Neue with magenta gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFD43AB6), Color(0xFFE02E8A)],
                      ).createShader(bounds),
                      child: Text(
                        'landing.revolution_title_1'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Bebas Neue',
                          height: 1.1,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    // Title 2 — Bebas Neue white with rocket emoji
                    Text(
                      'landing.revolution_title_2'.tr() + ' 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 32 : 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Bebas Neue',
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),
                    // Description — Poppins white
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 650,
                      ),
                      child: Text(
                        'landing.revolution_description'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    // CTA — Poppins magenta
                    Text(
                      'landing.revolution_cta'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD43AB6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds scattered decorative MigozzVector.png images for the background
  List<Widget> _buildDecorativeVectors(bool isMobile) {
    const vectorPath = 'assets/images/landing/MigozzVector.png';
    final double baseSize = isMobile ? 100 : 180;

    // Each item: (top%, left%, sizeFactor, rotationDegrees, opacity)
    // Positioned in pairs for organized look
    final positions = <List<double>>[
      // Top pair
      [-0.08, -0.05, 1.6, -15, 0.25],
      [-0.08, 0.87, 1.8, 20, 0.24],
      // Middle pair
      [0.35, -0.04, 1.7, 10, 0.23],
      [0.35, 0.88, 1.5, -25, 0.24],
      // Bottom pair
      [0.75, -0.05, 1.8, 35, 0.24],
      [0.75, 0.85, 1.6, 15, 0.25],
    ];

    return positions.map((p) {
      final top = p[0];
      final left = p[1];
      final sizeFactor = p[2];
      final rotation = p[3] * 3.14159 / 180;
      final opacity = p[4];
      final size = baseSize * sizeFactor;

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * top,
                    left: constraints.maxWidth * left,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Opacity(
                        opacity: opacity,
                        child: Image.asset(
                          vectorPath,
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }).toList();
  }
}
