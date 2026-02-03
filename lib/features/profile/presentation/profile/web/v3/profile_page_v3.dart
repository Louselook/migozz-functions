import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/profile_info_panel.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/profile_media_grid.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/web_complete_profile_modal.dart';
import 'package:migozz_app/features/chat/presentation/user/list/web_chat_list_widget.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';

class WebProfileContentV3 extends StatefulWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;

  const WebProfileContentV3({
    super.key,
    required this.user,
    required this.tutorialKeys,
  });

  @override
  State<WebProfileContentV3> createState() => _WebProfileContentV3State();
}

class _WebProfileContentV3State extends State<WebProfileContentV3> {
  bool _isChatOpen = false;
  final ChatService _chatService = ChatService();

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  void _closeChat() {
    setState(() {
      _isChatOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    // Calculate stats
    final totalFollowers = _calculateTotalFollowers(
      widget.user.socialEcosystem,
    );

    // Build social links
    final socialLinks = _buildSocialLinks(
      widget.user.socialEcosystem,
      widget.user.username,
    );

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUserEmail = authState.userProfile?.email ?? '';
        final isOwnProfile = widget.user.email == currentUserEmail;

        final isProfileComplete = isOwnProfile
            ? (authState.userProfile?.complete ?? true)
            : true;
        final hasSeenDialog = authState.hasSeenCompleteProfileDialog;

        final showCompleteModal =
            isOwnProfile && !isProfileComplete && !hasSeenDialog;

        // Stream unread count only if user is logged in
        final unreadStream = (currentUserEmail.isNotEmpty)
            ? _chatService.getTotalUnreadCountStream(currentUserEmail)
            : Stream.value(0);

        return StreamBuilder<int>(
          stream: unreadStream,
          initialData: 0,
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // Main Content Area with Padding for SideMenu
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(left: leftMenuWidth),
                      child: isSmallScreen
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Mobile Layout (Stacked)
                                  SizedBox(
                                    height: 600,
                                    child: ProfileInfoPanel(
                                      user: widget.user,
                                      socialLinks: socialLinks,
                                      communityCount: totalFollowers.toString(),
                                      isOwnProfile: isOwnProfile,
                                      unreadCount: isOwnProfile
                                          ? unreadCount
                                          : 0,
                                      onNotificationTap: isOwnProfile
                                          ? _toggleChat
                                          : null,
                                    ),
                                  ),
                                  ProfileMediaGrid(
                                    socialLinks: socialLinks,
                                    rawSocialData: widget.user.socialEcosystem,
                                    scrollingEnabled: false,
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Desktop Layout (Split)

                                // LEFT PANEL: User Info
                                Expanded(
                                  flex: 5,
                                  child: ProfileInfoPanel(
                                    user: widget.user,
                                    socialLinks: socialLinks,
                                    communityCount: totalFollowers.toString(),
                                    isOwnProfile: isOwnProfile,
                                    unreadCount: isOwnProfile ? unreadCount : 0,
                                    onNotificationTap: isOwnProfile
                                        ? _toggleChat
                                        : null,
                                  ),
                                ),

                                // RIGHT PANEL: Media Grid
                                Expanded(
                                  flex: 7,
                                  child: ProfileMediaGrid(
                                    socialLinks: socialLinks,
                                    rawSocialData: widget.user.socialEcosystem,
                                    scrollingEnabled: true,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Side Menu (Fixed on Left)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: leftMenuWidth,
                    child: SideMenu(
                      tutorialKeys: widget.tutorialKeys,
                      onChatTap: _toggleChat,
                      isChatOpen: _isChatOpen,
                      unreadCount: unreadCount,
                    ),
                  ),

                  // Chat Panel
                  if (_isChatOpen)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 350,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          border: const Border(
                            left: BorderSide(color: Colors.white12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.5),
                              blurRadius: 20,
                              offset: const Offset(-5, 0),
                            ),
                          ],
                        ),
                        child: WebChatListWidget(
                          username: widget.user.username.replaceFirst('@', ''),
                          currentUserId: currentUserEmail,
                          onClose: _closeChat,
                        ),
                      ),
                    ),

                  // Complete Profile Modal Overlay
                  if (showCompleteModal)
                    const Positioned.fill(child: WebCompleteProfileModal()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Methods ---

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

        // Initialize variables
        int? followers;
        int? shares;
        String? customUrl;
        String? profileImageUrl;

        if (data is Map<String, dynamic>) {
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();

          profileImageUrl =
              data['photoUrl']?.toString() ??
              data['profileUrl']?.toString() ??
              data['avatar']?.toString() ??
              data['image']?.toString();
        }

        final socialInfo = _getSocialInfo(platform, cleanUsername, customUrl);
        if (socialInfo != null) {
          links.add(
            SocialLink(
              asset: socialInfo['asset']!,
              url: Uri.parse(socialInfo['url']!),
              followers: followers,
              shares: shares,
              profileImageUrl: profileImageUrl,
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
    final normalizedLabel = platform.isNotEmpty
        ? (platform[0].toUpperCase() + platform.substring(1).toLowerCase())
        : platform;

    var asset = iconByLabel[normalizedLabel];

    if (asset == null) {
      final entry = iconByLabel.entries.firstWhere(
        (e) => e.key.toLowerCase() == platform.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );
      if (entry.key.isNotEmpty) asset = entry.value;
    }

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
      case 'facebook':
        url = customUrl ?? 'https://www.facebook.com/$username';
        break;
      case 'pinterest':
        url = customUrl ?? 'https://www.pinterest.com/$username';
        break;
      case 'youtube':
        url = customUrl ?? 'https://www.youtube.com/@$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/$username';
        break;
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/$username';
        break;
      case 'spotify':
        url = customUrl ?? 'https://open.spotify.com/user/$username';
        break;
      case 'linkedin':
        url = customUrl ?? 'https://www.linkedin.com/in/$username';
        break;
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}
