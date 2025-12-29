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
      child: photos.length == 1
          ? Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.29,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
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
                      imageUrl: photos.first.imageUrl,
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
                        padding: const EdgeInsets.all(3),
                        child: SvgPicture.asset(
                          photos.first.iconAsset,
                          fit: BoxFit.contain,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : photos.length == 2
              ? ListView.builder(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.symmetric(horizontal: 00, vertical: 0),
                  itemCount: photos.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return index == 0
                        ? Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.22,
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
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
                                    imageUrl: photos[index].imageUrl,
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
                                      padding: const EdgeInsets.all(3),
                                      child: SvgPicture.asset(
                                        photos[index].iconAsset,
                                        fit: BoxFit.contain,
                                        width: 16,
                                        height: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _PhotoCardWithAspectRatio(photo: photos[index], aspectRatio: 3);
                  },
                )
              : _buildFilledGrid(context, photos),
    );
  }

  Widget _buildFilledGrid(BuildContext context, List<SocialPhoto> photos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 2.0;

        // For 3 photos: 1 tall on left, 2 stacked on right
        if (photos.length == 3) {
          final halfWidth = (availableWidth - spacing) / 2;
          final itemHeight = halfWidth;

          return SizedBox(
            height: itemHeight * 2 + spacing,
            child: Row(
              children: [
                SizedBox(
                  width: halfWidth,
                  child: _PhotoCard(photo: photos[0]),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: halfWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: itemHeight,
                        child: _PhotoCard(photo: photos[1]),
                      ),
                      const SizedBox(height: spacing),
                      SizedBox(
                        height: itemHeight,
                        child: _PhotoCard(photo: photos[2]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // For 4+ photos: Staggered grid
        final cellSize = (availableWidth - spacing) / 2;

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            // Staggered heights: alternate between tall and short
            final heightMultiplier = (index % 3 == 0) ? 1.4 : (index % 3 == 1) ? 0.8 : 1.0;
            return SizedBox(
              height: cellSize * heightMultiplier,
              child: _PhotoCard(photo: photos[index]),
            );
          },
        );
      },
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

  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minSide = constraints.biggest.shortestSide;
        final radius = minSide * 0.05;
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
            borderRadius: BorderRadius.circular(radius),
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
    );
  }
}

class _PhotoCardWithAspectRatio extends StatelessWidget {
  final SocialPhoto photo;
  final double aspectRatio;

  const _PhotoCardWithAspectRatio({
    required this.photo,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minSide = constraints.biggest.shortestSide;
          final radius = minSide * 0.05;
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
