import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileHeaderV3 extends StatelessWidget {
  final String name;
  final String displayName;
  final String communityCount;
  final String communityName;
  final String? avatarUrl;
  final String voiceNoteUrl;
  final String? bio;
  final TutorialKeys? tutorialKeys;
  final bool isOwnProfile;
  final String userId;

  const ProfileHeaderV3({
    super.key,
    required this.name,
    required this.displayName,
    required this.communityCount,
    required this.communityName,
    this.avatarUrl,
    this.voiceNoteUrl = '',
    this.bio,
    this.tutorialKeys,
    this.isOwnProfile = true,
    this.userId = '',
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

        // Imagen de perfil circular para v3
        _ProfileImageV3(
          avatarUrl: avatarUrl,
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
          voiceNoteUrl: voiceNoteUrl,
          bio: bio,
          tutorialKeys: tutorialKeys,
          isOwnProfile: isOwnProfile,
          userId: userId,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProfileImageV3 extends StatelessWidget {
  final String? avatarUrl;
  final double screenWidth;
  final bool isSmallScreen;

  const _ProfileImageV3({
    this.avatarUrl,
    required this.screenWidth,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño medio para la versión 3
    final imageSize = screenWidth < 400
        ? 140.0
        : (isSmallScreen ? 160.0 : 200.0);

    final bool isNetworkImage =
        avatarUrl != null &&
        (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));
    final String fallbackAsset = 'assets/images/ImgPefil.webp';

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: isNetworkImage
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
      ),
    );
  }
}
