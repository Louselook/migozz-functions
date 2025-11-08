import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width, radius;
  final double height;
  final LinearGradient? gradient;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width = 90,
    this.height = 40,
    this.radius = 8,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }
}
