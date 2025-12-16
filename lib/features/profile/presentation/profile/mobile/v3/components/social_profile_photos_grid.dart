import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';

class SocialProfilePhotosGrid extends StatelessWidget {
  final List<Map<String, dynamic>>? socialEcosystem;

  const SocialProfilePhotosGrid({super.key, required this.socialEcosystem});

  @override
  Widget build(BuildContext context) {
    final photos = _extractPhotos();

    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        children: List.generate(photos.length, (index) {
          // Define staggered pattern similar to the image
          // Pattern: large (2x2), medium (2x1), small (1x1), small (1x1), etc.
          final patterns = [
            {'cross': 2, 'main': 2}, // Large square
            {'cross': 2, 'main': 1}, // Wide rectangle
            {'cross': 1, 'main': 1}, // Small square
            {'cross': 1, 'main': 2}, // Tall rectangle
            {'cross': 2, 'main': 1}, // Wide rectangle
            {'cross': 1, 'main': 1}, // Small square
            {'cross': 1, 'main': 2}, // Tall rectangle
            {'cross': 2, 'main': 2}, // Large square
          ];

          final pattern = patterns[index % patterns.length];
          final aspectRatio = pattern['cross']! / pattern['main']!;

          return StaggeredGridTile.count(
            crossAxisCellCount: pattern['cross']!,
            mainAxisCellCount: pattern['main']!,
            child: _PhotoCard(photo: photos[index], aspectRatio: aspectRatio),
          );
        }),
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
    return iconBlackByLabel[normalizedLabel];
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
  final double aspectRatio;

  const _PhotoCard({required this.photo, this.aspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minSide = constraints.biggest.shortestSide;
          final radius = minSide * 0.05;
          // const borderWidth = 2.0;
          return Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),

            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 40,
                        ),
                      );
                    },
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      // decoration: BoxDecoration(
                      //   color: Colors.black.withValues(alpha: 0.35),
                      //   borderRadius: BorderRadius.circular(8),
                      //   border: Border.all(
                      //     color: Colors.white.withValues(alpha: 0.18),
                      //     width: 1,
                      //   ),
                      // ),
                      padding: const EdgeInsets.all(3),
                      child: SvgPicture.asset(
                        photo.iconAsset,
                        fit: BoxFit.contain,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
