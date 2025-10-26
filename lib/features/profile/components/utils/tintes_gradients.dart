import 'package:flutter/material.dart';

class TintesGradients extends StatelessWidget {
  final Widget child;

  const TintesGradients({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tinte morado superior izq (radial)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.9), // arriba-izquierda
                radius: 0.8,
                colors: [
                  const Color.fromARGB(110, 184, 107, 255),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.9],
              ),
            ),
          ),
        ),

        // Gradiente dorado inferior, suave
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.9),
                radius: 1.5,
                colors: [
                  const Color.fromARGB(100, 243, 198, 35),
                  Colors.transparent,
                ],
                stops: const [0.1, 0.9],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
