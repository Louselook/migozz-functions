import 'package:flutter/material.dart';

/// Grid scrollable para las "cards" del perfil.
/// [count] = cantidad de items a generar.
/// [onTap] = callback opcional al tocar cada card.
/// [bottomExtraPadding] = espacio extra inferior (evita solaparse con el bottom nav/gradiente).
Widget buildProfileCardsGrid(
  BuildContext context, {
  int count = 12,
  void Function(int)? onTap,
  double bottomExtraPadding = 0,
}) {
  final size = MediaQuery.of(context).size;
  final width = size.width;

  // 3 columnas como antes
  final crossAxisCount = 3;
  final spacing = 6.0;
  final horizontalPadding = 12.0;
  final totalSpacing = spacing * (crossAxisCount - 1);
  final itemWidth = (width - totalSpacing - horizontalPadding) / crossAxisCount;
  final itemHeight = itemWidth * 1.2; // Más responsive basado en ancho

  return LayoutBuilder(
    builder: (context, constraints) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding / 2,
          12,
          horizontalPadding / 2,
          12 + bottomExtraPadding,
        ),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: itemWidth / itemHeight,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onTap?.call(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blueGrey.shade700,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: Text(
                '#$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
