import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String displayName;
  final String communityCount;
  final String communityName;
  final String imageAsset;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.displayName,
    required this.communityCount,
    required this.communityName,
    this.imageAsset = 'assets/img/ImgPefil.webp',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const minWidth = 360.0;
    final screenWidth = size.width < minWidth ? minWidth : size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 50 : 60),

        // Imagen de perfil con bordes redondeados
        _ProfileImage(
          imageAsset: imageAsset,
          screenWidth: screenWidth,
          isSmallScreen: isSmallScreen,
        ),

        const SizedBox(height: 12),

        // Info del usuario
        InfoUserProfile(
          name: name,
          displayName: displayName,
          comunityCount: communityCount,
          nameComunity: communityName,
          voiceNoteUrl: '',
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String imageAsset;
  final double screenWidth;
  final bool isSmallScreen;

  const _ProfileImage({
    required this.imageAsset,
    required this.screenWidth,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = screenWidth < 400
        ? 150.0
        : (isSmallScreen ? 180.0 : 320.0);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(27),
              ),
              child: Icon(
                Icons.person,
                size: isSmallScreen ? 60 : 80,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            );
          },
        ),
      ),
    );
  }
}
