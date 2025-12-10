import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/presentation/user/list/chats_list_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/profile_version_selector.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/qr_scanner_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/components/profile_top_actions.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class MobileProfileContent extends StatefulWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;

  const MobileProfileContent({
    super.key,
    required this.user,
    required this.tutorialKeys,
  });

  @override
  State<MobileProfileContent> createState() => _MobileProfileContentState();
}

class _MobileProfileContentState extends State<MobileProfileContent> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserEmail = authState.userProfile?.email ?? '';
    final isOwnProfile = widget.user.email == currentUserEmail;

    final user = isOwnProfile && authState.userProfile != null
        ? authState.userProfile!
        : widget.user;

    final name = user.displayName;
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';
    final avatarUrl = user.avatarUrl;
    final voiceNoteUrl = user.voiceNoteUrl ?? '';

    final totalFollowers = _calculateTotalFollowers(user.socialEcosystem);
    _buildSocialLinks(user.socialEcosystem, user.username);

    return Scaffold(
      body: BackgroundImage(
        avatarUrl: avatarUrl,
        tutorialKeys: widget.tutorialKeys,
        name: name.isNotEmpty ? name : 'NOMBRE VACÍO',
        displayName: username,
        comunityCount: totalFollowers.toString(),
        nameComunity: 'Community',
        voiceNoteUrl: voiceNoteUrl,
        isOwnProfile: isOwnProfile,
        userId: user.email,
        child: Stack(
          children: [
            // ✅ 3. TODOS LOS BOTONES SUPERIORES EN UN SOLO WIDGET
            ProfileTopActions(
              isOwnProfile: isOwnProfile,
              onMenuTap: () {
                // ✅ NUEVO callback
                if (isOwnProfile) {
                  showDialog(
                    context: context,
                    builder: (context) => ProfileVersionSelector(
                      currentVersion: user.profileVersion,
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              onQrScanTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
              },
              onChatTap: () {
                if (!isOwnProfile) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserChatScreen(
                        otherUserId: user.email,
                        otherUserName: user.displayName.isNotEmpty
                            ? user.displayName
                            : user.username,
                        otherUserAvatar: user.avatarUrl,
                        currentUserId: currentUserEmail,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatsListScreen(
                        username: user.username.replaceFirst('@', ''),
                        currentUserId: currentUserEmail,
                      ),
                    ),
                  );
                }
              },
              onNotificationsTap: () {
                debugPrint('Abrir notificaciones');
              },
            ),

            // if (socialLinks.isNotEmpty)
            //   DraggableSocialRail(
            //     initialPosition: initialSocialPosition,
            //     links: socialLinks,
            //     itemSize: 50,
            //     iconSize: 45,
            //   ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalFollowers(List<Map<String, dynamic>>? socialEcosystem) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return 0;
    int total = 0;
    for (final social in socialEcosystem) {
      for (final platformData in social.values) {
        if (platformData is Map<String, dynamic>) {
          final followers = platformData['followers'];
          if (followers is int) {
            total += followers;
          } else if (followers is String) {
            total += int.tryParse(followers) ?? 0;
          }
        }
      }
    }
    return total;
  }

  List<SocialLink> _buildSocialLinks(
    List<Map<String, dynamic>>? socialEcosystem,
    String username,
  ) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return [];
    final links = <SocialLink>[];
    final cleanUsername = username.replaceFirst('@', '');

    for (final social in socialEcosystem) {
      for (final entry in social.entries) {
        final platform = entry.key.toLowerCase();
        final data = entry.value;
        int? followers;
        int? shares;
        String? customUrl;

        if (data is Map<String, dynamic>) {
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();
        }

        final socialInfo = _getSocialInfo(platform, cleanUsername, customUrl);
        if (socialInfo != null) {
          links.add(
            SocialLink(
              asset: socialInfo['asset']!,
              url: Uri.parse(socialInfo['url']!),
              followers: followers,
              shares: shares,
            ),
          );
        }
      }
    }
    return links;
  }

  int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, String>? _getSocialInfo(
    String platform,
    String username,
    String? customUrl,
  ) {
    final normalizedLabel =
        platform[0].toUpperCase() + platform.substring(1).toLowerCase();

    final asset = iconByLabel[normalizedLabel];
    if (asset == null) return null;

    String url;
    switch (platform) {
      case 'tiktok':
        url = customUrl ?? 'https://www.tiktok.com/@$username';
        break;
      case 'instagram':
        url = customUrl ?? 'https://www.instagram.com/$username';
        break;
      case 'x':
      case 'twitter':
        url = customUrl ?? 'https://x.com/$username';
        break;
      case 'pinterest':
        url = customUrl ?? 'https://www.pinterest.com/$username';
        break;
      case 'youtube':
        url = customUrl ?? 'https://www.youtube.com/@$username';
        break;
      case 'linkedin':
        url = customUrl ?? '';
        break;
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}
