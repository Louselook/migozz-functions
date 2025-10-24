import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/publication_item.dart';

class PublicationsGrid extends StatelessWidget {
  final List<String> images;
  final Function(int)? onPublicationTap;

  const PublicationsGrid({
    super.key,
    required this.images,
    this.onPublicationTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;

    final isVerySmallScreen = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    // Responsive: Grid settings - 1 columna en pantallas muy pequeñas
    final crossAxisCount = isVerySmallScreen
        ? 1
        : (isSmallScreen ? 2 : (isMediumScreen ? 3 : 4));

    final gridSpacing = isVerySmallScreen ? 12.0 : (isSmallScreen ? 8.0 : 12.0);

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        // Simular algunos items con diferentes tipos de contenido
        final isVideo = index % 5 == 0;
        final isMultiple = index % 7 == 0;

        return PublicationItem(
          index: index,
          imageAsset: images[index],
          isVideo: isVideo,
          isMultiple: isMultiple,
          onTap: onPublicationTap != null
              ? () => onPublicationTap!(index)
              : null,
        );
      },
    );
  }
}
