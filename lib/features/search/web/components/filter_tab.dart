import 'package:flutter/material.dart';

/// Tab individual del filtro de búsqueda
class FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;
  final double indicatorWidth;
  final double horizontalPadding;
  final Color selectedColor;

  const FilterTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.fontSize,
    required this.indicatorWidth,
    required this.horizontalPadding,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
              ),
            ),
            const SizedBox(height: 6),
            // Bottom border indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 2.5,
              width: isSelected ? indicatorWidth : 0,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor
                    : const Color.fromARGB(0, 255, 255, 255),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
