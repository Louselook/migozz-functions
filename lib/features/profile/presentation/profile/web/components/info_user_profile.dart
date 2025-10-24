import 'package:flutter/material.dart';

class InfoUserProfile extends StatelessWidget {
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;

  const InfoUserProfile({
    super.key,
    required this.name,
    required this.displayName,
    required this.comunityCount,
    required this.nameComunity,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Establecer ancho mínimo
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;

    final isVerySmallScreen = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;

    // Responsive: Font sizes ajustados para pantallas muy pequeñas
    final nameFontSize = isVerySmallScreen
        ? 22.0
        : (isSmallScreen ? 26.0 : 32.0);
    final displayNameFontSize = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);
    final communityFontSize = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);
    final iconSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 24.0 : 28.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
        vertical: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre con iconos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: iconSize,
              ),
              const SizedBox(width: 4),
              Icon(Icons.share, color: Colors.white, size: iconSize),
            ],
          ),

          const SizedBox(height: 6),

          // Username
          Text(
            displayName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: displayNameFontSize,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 14),

          // Fila de community con iconos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: iconSize),
              SizedBox(width: isVerySmallScreen ? 12 : 16),
              Icon(
                Icons.card_giftcard,
                color: const Color(0xFF00FF7F),
                size: iconSize,
              ),
              SizedBox(width: isVerySmallScreen ? 6 : 8),
              Text(
                comunityCount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: communityFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                nameComunity,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: communityFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 12 : 16),
              Icon(Icons.send, color: Colors.white, size: iconSize),
              SizedBox(width: isVerySmallScreen ? 8 : 12),
              Icon(Icons.link, color: Colors.white, size: iconSize),
            ],
          ),
        ],
      ),
    );
  }
}
