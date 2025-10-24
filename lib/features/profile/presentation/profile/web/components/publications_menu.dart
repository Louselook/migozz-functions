import 'package:flutter/material.dart';

class PublicationsMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuChanged;

  const PublicationsMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;

    final isVerySmallScreen = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;

    final iconSize = isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final menuWidth = isVerySmallScreen
        ? 140.0
        : (isSmallScreen ? 160.0 : 200.0);

    return Center(
      child: Container(
        width: menuWidth,
        height: isSmallScreen ? 44 : 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MenuButton(
              icon: Icons.grid_on,
              index: 0,
              iconSize: iconSize,
              isSelected: selectedIndex == 0,
              onTap: () => onMenuChanged(0),
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            _MenuButton(
              icon: Icons.play_circle_outline,
              index: 1,
              iconSize: iconSize,
              isSelected: selectedIndex == 1,
              onTap: () => onMenuChanged(1),
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            _MenuButton(
              icon: Icons.all_inclusive,
              index: 2,
              iconSize: iconSize,
              isSelected: selectedIndex == 2,
              onTap: () => onMenuChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final int index;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.index,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
