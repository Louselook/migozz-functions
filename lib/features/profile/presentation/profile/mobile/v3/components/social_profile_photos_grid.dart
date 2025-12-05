import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';

class SocialProfilePhotosGrid extends StatelessWidget {
  final List<Map<String, dynamic>>? socialEcosystem;

  const SocialProfilePhotosGrid({super.key, required this.socialEcosystem});

  @override
  Widget build(BuildContext context) {
    final photos = _extractPhotos();

    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return _PhotoCard(photo: photos[index]);
        },
      ),
    );
  }

  List<SocialPhoto> _extractPhotos() {
    if (socialEcosystem == null || socialEcosystem!.isEmpty) return [];

    final photos = <SocialPhoto>[];

    for (final social in socialEcosystem!) {
      for (final entry in social.entries) {
        final platform = entry.key.toLowerCase();
        final data = entry.value;

        if (data is Map<String, dynamic>) {
          final profileImageUrl = data['profile_image_url']?.toString();

          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            final iconAsset = _getIconAsset(platform);
            if (iconAsset != null) {
              photos.add(
                SocialPhoto(
                  imageUrl: profileImageUrl,
                  platform: platform,
                  iconAsset: iconAsset,
                ),
              );
            }
          }
        }
      }
    }

    return photos;
  }

  String? _getIconAsset(String platform) {
    final normalizedLabel =
        platform[0].toUpperCase() + platform.substring(1).toLowerCase();
    return iconByLabel[normalizedLabel];
  }
}

class SocialPhoto {
  final String imageUrl;
  final String platform;
  final String iconAsset;

  SocialPhoto({
    required this.imageUrl,
    required this.platform,
    required this.iconAsset,
  });
}

class _PhotoCard extends StatelessWidget {
  final SocialPhoto photo;

  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE91E63), // Color rosa/magenta del borde
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de perfil
            Image.network(
              photo.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),

            // Ícono de la red social en la esquina inferior derecha
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: SvgPicture.asset(photo.iconAsset, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
