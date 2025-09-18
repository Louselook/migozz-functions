import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class CustomProgressIndicator extends StatelessWidget {
  final int index;
  final int currentIndex;

  // Personalizables
  final double activeWidth;
  final double inactiveWidth;
  final double activeHeight;
  final double inactiveHeight;
  final Color activeColor;
  final Color inactiveColor;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const CustomProgressIndicator(
    this.index, {
    super.key,
    required this.currentIndex,
    this.activeWidth = 80,
    this.inactiveWidth = 40,
    this.activeHeight = 8,
    this.inactiveHeight = 5,
    this.activeColor = AppColors.primaryPink,
    this.inactiveColor = Colors.grey,
    this.borderRadius = const BorderRadius.all(Radius.circular(2)),
    this.margin = const EdgeInsets.symmetric(horizontal: 5),
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: margin,
      width: isActive ? activeWidth : inactiveWidth,
      height: isActive ? activeHeight : inactiveHeight,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.3),
        borderRadius: borderRadius,
      ),
    );
  }
}
