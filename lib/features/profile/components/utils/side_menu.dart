// lib/features/profile/components/side_menu.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    // Responsive: Menu width
    final menuWidth = isSmallScreen
        ? 90.0
        : isMediumScreen
        ? 100.0
        : 150.0;

    // Responsive: Border radius
    final borderRadius = isSmallScreen ? 15.0 : 20.0;

    // Responsive: Create button size
    final createButtonSize = isSmallScreen
        ? 56.0
        : isMediumScreen
        ? 60.0
        : 64.0;

    final createIconSize = isSmallScreen
        ? 28.0
        : isMediumScreen
        ? 30.0
        : 32.0;

    final createFontSize = isSmallScreen
        ? 10.0
        : isMediumScreen
        ? 11.0
        : 12.0;

    return Container(
      width: menuWidth,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        border: Border(
          right: BorderSide(
            color: const Color.fromARGB(
              209,
              255,
              255,
              255,
            ).withValues(alpha: 0.6),
            width: isSmallScreen ? 1.5 : 2.0,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 15.0 : 20.0),

          // Menú items
          Expanded(
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'profile',
                  isSelected: true,
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  onTap: () {
                    // Ya estamos en el perfil
                  },
                ),
                _MenuItem(
                  icon: Icons.link,
                  label: 'Feed',
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  onTap: () {
                    // context.go('/feed');
                  },
                ),
                _MenuItem(
                  icon: Icons.bar_chart,
                  label: 'My Stats juan',
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  onTap: () {
                    debugPrint('hola');
                    context.go('/stats');
                  },
                ),
                _MenuItem(
                  icon: Icons.settings,
                  label: 'Configuration',
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  onTap: () {
                    context.go('/edit-profile');
                  },
                ),
              ],
            ),
          ),

          // Botón Create en la parte inferior
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 20.0 : 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: createButtonSize,
                  height: createButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF0050), Color(0xFFFF6B9D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0050).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.go('/create');
                      },
                      borderRadius: BorderRadius.circular(createButtonSize / 2),
                      child: Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: createIconSize,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: createFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive: Icon size
    final iconSize = isSmallScreen
        ? 24.0
        : isMediumScreen
        ? 26.0
        : 28.0;

    // Responsive: Font size
    final fontSize = isSmallScreen
        ? 9.0
        : isMediumScreen
        ? 10.0
        : 11.0;

    // Responsive: Padding
    final verticalPadding = isSmallScreen
        ? 12.0
        : isMediumScreen
        ? 14.0
        : 16.0;

    final horizontalPadding = isSmallScreen
        ? 8.0
        : isMediumScreen
        ? 10.0
        : 12.0;

    final spacing = isSmallScreen ? 4.0 : 6.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF0050) : Colors.white70,
              size: iconSize,
            ),
            SizedBox(height: spacing),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF0050) : Colors.white70,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
