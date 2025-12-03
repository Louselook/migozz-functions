import 'dart:ui';
import 'package:flutter/material.dart';

class ProfileImageMobileV3 extends StatelessWidget {
  final String? avatarUrl;
  final Size size;

  const ProfileImageMobileV3({super.key, this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageSize = size.width;

    final bool isNetworkImage =
        avatarUrl != null &&
        (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));
    const String fallbackAsset = 'assets/images/ImgPefil.webp';

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          isNetworkImage
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(fallbackAsset, fit: BoxFit.cover);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                )
              : Image.asset(
                  avatarUrl ?? fallbackAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(fallbackAsset, fit: BoxFit.cover);
                  },
                ),

          // Gradiente de difuminación más fuerte y corto
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: imageSize * 0.15,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
