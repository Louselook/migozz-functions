import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/publications_grid.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/publications_menu.dart';

class PublicationsContent extends StatefulWidget {
  const PublicationsContent({super.key});

  @override
  State<PublicationsContent> createState() => _PublicationsContentState();
}

class _PublicationsContentState extends State<PublicationsContent> {
  int _selectedMenuIndex = 0;

  static const List<String> _images = [
    'assets/img/ImageUno.webp',
    'assets/img/ImageTwo.webp',
    'assets/img/ImageThree.webp',
    'assets/img/ImgPefil.webp',
    'assets/img/onboarding1.webp',
    'assets/img/onboarding2.webp',
    'assets/img/onboarding3.webp',
    'assets/img/profileBackground.webp',
    'assets/img/Migozz.webp',
    'assets/img/otp_image.webp',
    'assets/img/logomigozz.png',
    'assets/img/ImgPefil.webp',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;

    final isVerySmallScreen = screenWidth < 400;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;

    final contentWidth = isVerySmallScreen
        ? screenWidth * 0.9
        : (isSmallScreen
              ? screenWidth * 0.8
              : (isMediumScreen ? screenWidth * 0.7 : screenWidth * 0.65));

    return Container(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            children: [
              PublicationsMenu(
                selectedIndex: _selectedMenuIndex,
                onMenuChanged: (index) {
                  setState(() {
                    _selectedMenuIndex = index;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PublicationsGrid(
                  images: _images,
                  onPublicationTap: (index) {
                    debugPrint('Publication $index tapped');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
