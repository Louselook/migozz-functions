import 'package:flutter/material.dart';

class PublicationItem extends StatelessWidget {
  final int index;
  final String imageAsset;
  final bool isVideo;
  final bool isMultiple;
  final VoidCallback? onTap;

  const PublicationItem({
    super.key,
    required this.index,
    required this.imageAsset,
    this.isVideo = false,
    this.isMultiple = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen real
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            // Overlay oscuro sutil
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Indicador de video
            if (isVideo)
              Positioned(
                top: 8,
                right: 8,
                child: _ContentIndicator(
                  icon: Icons.play_circle_filled,
                  isSmallScreen: isSmallScreen,
                ),
              ),

            // Indicador de múltiples imágenes
            if (isMultiple && !isVideo)
              Positioned(
                top: 8,
                right: 8,
                child: _ContentIndicator(
                  icon: Icons.collections,
                  isSmallScreen: isSmallScreen,
                ),
              ),

            // Overlay hover interactivo
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      onTap ??
                      () {
                        debugPrint('Publication $index tapped');
                      },
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentIndicator extends StatelessWidget {
  final IconData icon;
  final bool isSmallScreen;

  const _ContentIndicator({required this.icon, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 24),
    );
  }
}
