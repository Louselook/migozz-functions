import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSearchButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileSearchButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;

    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    // Responsive: Tamaño del icono de búsqueda
    final searchIconSize = isSmallScreen
        ? 28.0
        : isMediumScreen
        ? 42.0
        : 46.0;

    // Responsive: Posición del icono de búsqueda
    final searchIconLeft = isSmallScreen
        ? 140.0
        : isMediumScreen
        ? 130.0
        : 180.0;

    final searchIconTop = isSmallScreen
        ? 20.0
        : isMediumScreen
        ? 24.0
        : 28.0;

    return Positioned(
      left: searchIconLeft,
      top: searchIconTop,
      child: GestureDetector(
        onTap: onTap ?? () => context.go('/search'),
        child: Icon(
          Icons.search,
          color: const Color(0xAAFFFFFF),
          size: searchIconSize,
        ),
      ),
    );
  }
}
