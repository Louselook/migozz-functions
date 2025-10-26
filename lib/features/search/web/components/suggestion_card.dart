import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Card individual para mostrar una sugerencia de reel
class SuggestionCard extends StatelessWidget {
  final String image;
  final String name;
  final String location;
  final String views;
  final double scale;

  const SuggestionCard({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    required this.views,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cornerRadius = (6.0 * scale).clamp(4.0, 10.0);
    final topIconPadding = (4.0 * scale).clamp(3.0, 6.0);
    final topIconSize = (12.0 * scale).clamp(10.0, 16.0);
    final gradientPadding = (4.0 * scale).clamp(3.0, 6.0);
    final avatarSize = (24.0 * scale).clamp(20.0, 32.0);
    final nameFont = (10.0 * scale).clamp(9.0, 12.0);
    final locationFont = (8.0 * scale).clamp(7.0, 10.0);
    final iconSize = (14.0 * scale).clamp(12.0, 18.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Material(
        color: Colors.grey.shade900,
        child: InkWell(
          onTap: () {},
          child: Stack(
            children: [
              // Imagen de fondo
              _buildBackgroundImage(),

              // Icono superior derecho
              _buildReelIcon(topIconPadding, topIconSize, scale),

              // Información inferior con gradiente
              _buildBottomInfo(
                gradientPadding,
                avatarSize,
                nameFont,
                locationFont,
                iconSize,
                scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildReelIcon(double padding, double iconSize, double scale) {
    return Positioned(
      top: padding,
      right: padding,
      child: Container(
        padding: EdgeInsets.all((3.0 * scale).clamp(2.0, 5.0)),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular((4.0 * scale).clamp(3.0, 6.0)),
        ),
        child: SvgPicture.asset(
          'assets/icons/instagram-reel.svg',
          width: iconSize,
          height: iconSize,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildBottomInfo(
    double padding,
    double avatarSize,
    double nameFont,
    double locationFont,
    double iconSize,
    double scale,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            _buildAvatar(avatarSize, scale),
            SizedBox(width: (4.0 * scale).clamp(3.0, 6.0)),
            // Nombre y ubicación
            Expanded(child: _buildUserInfo(nameFont, locationFont, scale)),
            // Contador de views
            _buildViewsCounter(iconSize, locationFont),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double size, double scale) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: (0.8 * scale).clamp(0.5, 1.2),
        ),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUserInfo(double nameFont, double locationFont, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: nameFont,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: (0.5 * scale).clamp(0.5, 2.0)),
        Text(
          location,
          style: TextStyle(color: Colors.white60, fontSize: locationFont),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildViewsCounter(double iconSize, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.play_arrow, color: Colors.white70, size: iconSize),
        Text(
          views,
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
