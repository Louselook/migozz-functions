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
                  const Color.fromARGB(174, 184, 107, 255),
                  const Color.fromARGB(144, 0, 0, 0),
                ],
                stops: const [0.15, 0.75],
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
                  const Color.fromARGB(181, 243, 198, 35),
                  const Color.fromARGB(144, 0, 0, 0),
                ],
                stops: const [0.02, 0.35],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
