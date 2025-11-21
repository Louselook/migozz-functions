import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/presentation/user/list/chats_list_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/profile_version_button.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/components/profile_top_actions.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/search/mobile/presentation/search_screen.dart';

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
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;
    final initialSocialPosition = Offset(size.width - 65, size.height * 0.2);

    final name = user.displayName;
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';
    final avatarUrl = user.avatarUrl;
    final voiceNoteUrl = user.voiceNoteUrl ?? '';

    // Determinar si es el perfil del usuario autenticado
    final authState = context.watch<AuthCubit>().state;
    final currentUserEmail = authState.userProfile?.email ?? '';
    final isOwnProfile = user.email == currentUserEmail;

    // Recuperamos los seguidores y redes desde el perfil
    final totalFollowers = _calculateTotalFollowers(user.socialEcosystem);
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

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
            // Botón de búsqueda
            if (isOwnProfile) // Condicional para busqueda
              Positioned(
                left: 10,
                top: 45,
                child: GestureDetector(
                  key: widget.tutorialKeys.searchScreenKey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: const Icon(
                    Icons.search,
                    color: Color(0xAAFFFFFF),
                    size: 45,
                  ),
                ),
              ),

            ProfileTopActions(
              isOwnProfile: isOwnProfile,
              onChatTap: () {
                if (!isOwnProfile) {
                  // Chat con otro usuario - Pasar datos básicos
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
                  // Mis chats - Ir a la lista
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatsListScreen(
                        username: user.username.replaceFirst('@', ''),
                        currentUserId: currentUserEmail, // ← Usar email, NO uid
                      ),
                    ),
                  );
                }
              },
              onNotificationsTap: () {
                debugPrint('Abrir notificaciones');
              },
            ),

            // Panel lateral de redes sociales
            if (socialLinks.isNotEmpty)
              DraggableSocialRail(
                initialPosition: initialSocialPosition,
                links: socialLinks,
                itemSize: 50,
                iconSize: 45,
              ),

            // Barra inferior de navegación
            if (isOwnProfile) // Condicional
              Align(
                alignment: Alignment.bottomCenter,
                child: GradientBottomNav(
                  currentIndex: _tab,
                  onItemSelected: (i) => setState(() => _tab = i),
                  onCenterTap: () async {
                    await context.read<AuthCubit>().logout();
                  },
                  onProfileUpdated: () {
                    context.read<AuthCubit>().refreshUserProfile();
                  },
                  tutorialKeys: widget.tutorialKeys,
                ),
              ),

            // Botón para cambiar versión de perfil
            ProfileVersionButton(currentVersion: user.profileVersion),
          ],
        ),
      ),
    );
  }

  // Calcular total de seguidores
  int _calculateTotalFollowers(List<Map<String, dynamic>>? socialEcosystem) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return 0;
    int total = 0;
    for (final social in socialEcosystem) {
      debugPrint('redes $socialEcosystem');
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


  // Construir enlaces de redes
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

  // Generar URL + ícono por red
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
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}
