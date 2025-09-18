import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width, radius;
  final double height;
  final Color color;

  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width = 90,
    this.height = 40,
    this.radius = 8,
    this.color = AppColors.backgroundGoole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
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
