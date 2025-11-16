import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileHeaderMobileV2 extends StatelessWidget {
  final String name;
  final String displayName;
  final String communityCount;
  final String communityName;
  final String? avatarUrl;
  final String voiceNoteUrl;
  final TutorialKeys? tutorialKeys;
  final bool isOwnProfile;
  final String userId;

  const ProfileHeaderMobileV2({
    super.key,
    required this.name,
    required this.displayName,
    required this.communityCount,
    required this.communityName,
    this.avatarUrl,
    this.voiceNoteUrl = '',
    this.tutorialKeys,
    this.isOwnProfile = true,
    this.userId = '',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        SizedBox(height: size.height * 0.08),

        // Imagen de perfil circular
        _ProfileImageMobileV2(avatarUrl: avatarUrl, size: size),

        const SizedBox(height: 12),

        // Info del usuario
        InfoUserProfile(
          name: name,
          displayName: displayName,
          comunityCount: communityCount,
          nameComunity: communityName,
          voiceNoteUrl: voiceNoteUrl,
          tutorialKeys: tutorialKeys,
          isOwnProfile: isOwnProfile,
          userId: userId,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _ProfileImageMobileV2 extends StatelessWidget {
  final String? avatarUrl;
  final Size size;

  const _ProfileImageMobileV2({this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageSize = size.width * 0.35; // 35% del ancho de la pantalla

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
