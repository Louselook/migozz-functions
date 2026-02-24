import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class TintesGradients extends StatelessWidget {
  final Widget child;

  const TintesGradients({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Circle 1: purple (top-left)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.85),
                  radius: 0.7,
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Circle 2: pink/purple (bottom-right)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, 0.75),
                  radius: 0.9,
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
