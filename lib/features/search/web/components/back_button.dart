import 'package:flutter/material.dart';

/// Botón de retroceso con icono de flecha
class BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final double iconSize;

  const BackButton({super.key, required this.onTap, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(iconSize),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.arrow_back, size: iconSize, color: Colors.white),
      ),
    );
  }
}
