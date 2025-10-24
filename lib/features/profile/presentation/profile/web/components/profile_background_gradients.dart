import 'package:flutter/material.dart';

class ProfileBackgroundGradients extends StatelessWidget {
  const ProfileBackgroundGradients({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Gradiente morado superior izquierdo
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.9),
                  radius: 0.5,
                  colors: [
                    const Color(0xFF9D43A5).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Gradiente dorado inferior derecho
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * 0.5,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, 1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFFF3C623).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 0.85],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
