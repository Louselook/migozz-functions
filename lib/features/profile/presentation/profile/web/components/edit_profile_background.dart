import 'package:flutter/material.dart';

class EditProfileBackground extends StatelessWidget {
  const EditProfileBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Purple gradient - top left
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.9),
                radius: 0.6,
                colors: [
                  const Color(0xFF9747FF).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Gold gradient - bottom right
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 1.0),
                radius: 0.8,
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
