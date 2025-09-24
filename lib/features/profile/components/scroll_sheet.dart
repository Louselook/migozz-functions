import 'package:flutter/material.dart';

/// Construye las "cards" del grid del perfil.
/// [count] = cantidad de items a generar.
/// [onTap] = callback opcional al tocar cada card.
Widget buildProfileCards(
  BuildContext context, {
  int count = 12,
  void Function(int)? onTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 15),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(count, (index) {
        return GestureDetector(
          onTap: () => onTap?.call(index),
          child: Container(
            width: (MediaQuery.of(context).size.width - 18) / 3,
            height: 150,
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
      }),
    ),
  );
}
