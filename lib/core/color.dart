import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFD43AB6);
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color textLight = Colors.white;
  static const Color secondaryText = Color(0xFFDEDEDE);
  static const Color textDark = Color(0xFF374151);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color radialEffect = Color(0xFFED4C5C);
  static const Color textInputBackGround = Color.fromARGB(255, 99, 99, 99);
  static const Color backgroundGoole = Color(0xFF404040);

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFFF89A44), Color(0xFFD43AB6), Color(0xFF9321BD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get verticalPinkPurple => const LinearGradient(
    colors: [Color(0xFFB930B9), Color(0xFFE26087)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// Modificar los colores
