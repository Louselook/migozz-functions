import 'package:flutter/material.dart';

/// Contenedor principal del contenido de búsqueda con padding calculado
class SearchContentContainer extends StatelessWidget {
  final double sideMenuWidth;
  final double horizontalPadding;
  final Widget child;

  const SearchContentContainer({
    super.key,
    required this.sideMenuWidth,
    required this.horizontalPadding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      left: sideMenuWidth + horizontalPadding,
      right: horizontalPadding,
      child: child,
    );
  }
}
