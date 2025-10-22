// lib/widgets/logo.dart
import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  // usar una instancia estática evita recrearla cada build
  static const AssetImage _asset = AssetImage('assets/images/Migozz.webp');

  final double width;
  final double height;
  final Color? iconColor;

  const Logo({
    super.key,
    this.width = 99,
    this.height = 98,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.image, color: iconColor);
      },
    );
  }
}
