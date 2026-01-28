import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/presentation/user/list/chats_list_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/data/datasources/follower_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/components/profile_top_actions.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/profile_image_mobile_v3.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/social_profile_photos_grid.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/profile_screen_v3_edit.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/qr_scanner_screen.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';

class MobileProfileContent extends StatefulWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;

  /// UID del usuario target (opcional, se busca por email si no se proporciona)
  final String? targetUserId;

  const MobileProfileContent({
    super.key,
    required this.user,
    required this.tutorialKeys,
    this.profileTutorialKeys,
    this.targetUserId,
  });

  @override
  State<MobileProfileContent> createState() => _MobileProfileContentState();
}

class _MobileProfileContentState extends State<MobileProfileContent> {
  /// UID del usuario que estamos viendo (se carga async si no se proporcionó)
  String? _resolvedTargetUserId;

  @override
  void initState() {
    super.initState();
    _resolveTargetUserId();
  }

  /// Resuelve el UID del usuario target
  Future<void> _resolveTargetUserId() async {
    // Si ya tenemos el uid, usarlo
    if (widget.targetUserId != null && widget.targetUserId!.isNotEmpty) {
      setState(() {
        _resolvedTargetUserId = widget.targetUserId;
      });
      return;
    }

    // Verificar si es el perfil propio
    final authState = context.read<AuthCubit>().state;
    final currentUserEmail = authState.userProfile?.email ?? '';
    final isOwnProfile = widget.user.email == currentUserEmail;

    if (isOwnProfile) {
      // Para perfil propio, usar el uid del usuario autenticado
      setState(() {
        _resolvedTargetUserId = authState.firebaseUser?.uid;
      });
      return;
    }

    // Buscar el uid por email del target user
    setState(() {});

    try {
      context.read<FollowerCubit>();
      // Acceder al servicio para buscar el uid
      final followerService = FollowerService();
      final uid = await followerService.getUserIdByEmail(widget.user.email);
      if (mounted) {
        setState(() {
          _resolvedTargetUserId = uid;
        });
      }
    } catch (e) {
      debugPrint('❌ [MobileProfileContent] Error resolviendo UID: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Detectar si podemos hacer pop o si debemos navegar a home
  bool _canPop() {
    // Verificar si hay historial de navegación
    return Navigator.of(context).canPop();
  }

  void _handleBackNavigation() {
    if (_canPop()) {
      // Si hay historial, hacer pop normal
      Navigator.of(context).pop();
    } else {
      // Si no hay historial (llegó por deep link), ir al perfil propio
      final authState = context.read<AuthCubit>().state;
      final currentUserEmail = authState.userProfile?.email ?? '';
      final isOwnProfile = widget.user.email == currentUserEmail;

      if (!isOwnProfile) {
        // Si estás viendo otro perfil, ir a tu perfil
        context.go('/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;

    final name = user.displayName;
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';
    final avatarUrl = user.avatarUrl;
    final voiceNoteUrl = user.voiceNoteUrl ?? '';

    // Determinar si es el perfil del usuario autenticado
    final authState = context.watch<AuthCubit>().state;
    final currentUserEmail = authState.userProfile?.email ?? '';
    final currentUserId = authState.firebaseUser?.uid; // UID del usuario actual
    final isOwnProfile = user.email == currentUserEmail;

    // Obtener seguidores de la app para sumar al community count
    final followerState = context.watch<FollowerCubit>().state;
    final appFollowers = isOwnProfile ? followerState.followersCount : 0;

    // Recuperamos los seguidores y redes desde el perfil
    final socialFollowers = _calculateTotalFollowers(user.socialEcosystem);
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);
    // Para el cambio de número al tocar "community" solo se debe mostrar:
    // - Community (por defecto)
    // - Seguidores de Migozz (la propia plataforma)
    final socialNetworksData = <SocialNetworkData>[
      SocialNetworkData(
        name: 'Migozz',
        followers: appFollowers,
        iconPath: iconByLabel['Migozz'] ?? 'assets/icons/social_networks/Other.svg',
      ),
    ];
    final bool hasSocials = socialLinks.isNotEmpty;
    final double socialsImageBottom = size.height * 0.43;
    final double socialsTopSpacer = size.height * 0.33;
    final totalFollowers = socialFollowers + appFollowers;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            // FOTO FULLSCREEN (si no hay redes)
            if (!hasSocials)
              Positioned.fill(
                child: ProfileImageMobileV3(size: size, avatarUrl: avatarUrl),
              ),

            // FOTO "top" si hay redes
            if (hasSocials)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: socialsImageBottom,
                child: ProfileImageMobileV3(
                  avatarUrl: avatarUrl,
                  size: Size(size.width, size.height - socialsImageBottom),
                ),
              ),

            // 3A) SIN REDES -> profilhero: card flotante abajo (no scroll)
            if (!hasSocials)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  bottom: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: _InfoCardGlass(
                      child: InfoUserProfile(
                        name: name.isNotEmpty
                            ? name
                            : 'profile.presentation.emptyName'.tr(),
                        displayName: username,
                        comunityCount: totalFollowers.toString(),
                        nameComunity: 'profile.presentation.community'.tr(),
                        voiceNoteUrl: voiceNoteUrl,
                        bio: user.bio,
                        tutorialKeys: widget.tutorialKeys,
                        profileTutorialKeys: widget.profileTutorialKeys,
                        isOwnProfile: isOwnProfile,
                        userId: user.email,
                        socialNetworks: socialNetworksData,
                        contactEmail: isOwnProfile ? null : user.contactEmail,
                        contactWebsite: isOwnProfile
                            ? null
                            : user.contactWebsite,
                        onMessageTap: () {
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
                      ),
                    ),
                  ),
                ),
              ),

            // 3B) CON REDES -> Estructura como SocialEcosystemStepV3:
            // foto fija + info fija + scroll solo en la sección de redes
            if (hasSocials)
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: socialsTopSpacer),
                    InfoUserProfile(
                      name: name.isNotEmpty
                          ? name
                          : 'profile.presentation.emptyName'.tr(),
                      displayName: username,
                      comunityCount: totalFollowers.toString(),
                      nameComunity: 'profile.presentation.community'.tr(),
                      voiceNoteUrl: voiceNoteUrl,
                      bio: user.bio,
                      tutorialKeys: widget.tutorialKeys,
                      profileTutorialKeys: widget.profileTutorialKeys,
                      isOwnProfile: isOwnProfile,
                      userId: user.email,
                      socialNetworks: socialNetworksData,
                      contactEmail: isOwnProfile ? null : user.contactEmail,
                      contactWebsite: isOwnProfile ? null : user.contactWebsite,
                      onMessageTap: () {
                        debugPrint("pulsado el chat");
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
                    ),
                    Expanded(
                      key: widget.profileTutorialKeys?.linkedNetworksKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 0),
                              child: SocialCirclesMobileV3(links: socialLinks),
                            ),
                            SocialProfilePhotosGrid(
                              socialEcosystem: user.socialEcosystem,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4) Botones siempre arriba (SafeArea)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ProfileTopActions(
                  isOwnProfile: isOwnProfile,
                  profilePercentage: _calculateProfileStrength(user),
                  targetUserId: isOwnProfile ? null : _resolvedTargetUserId,
                  currentUserId: isOwnProfile ? null : currentUserId,
                  profileTutorialKeys: widget.profileTutorialKeys,
                  onMenuTap: () {
                    if (isOwnProfile) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MobileProfileContentV3Edit(
                            user: user,
                            tutorialKeys: widget.tutorialKeys,
                          ),
                        ),
                      );
                    } else {
                      // 🔥 Usar el handler inteligente de navegación
                      _handleBackNavigation();
                    }
                  },
                  onQrScanTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QrScannerScreen(),
                      ),
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
                    context.push('/notifications');
                  },
                ),
              ),
            ),
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
      final type = social['type']?.toString().toLowerCase();
      if (type == 'custom') {
        final url = social['url']?.toString() ?? '';
        final iconUrl = social['iconUrl']?.toString();
        final domain = social['domain']?.toString() ?? '';
        final assetUrl = (iconUrl != null && iconUrl.startsWith('http'))
            ? iconUrl
            : _faviconFromDomain(domain);
        if (assetUrl.isNotEmpty && url.isNotEmpty) {
          links.add(
            SocialLink(
              asset: assetUrl,
              url: Uri.parse(url),
              followers: null,
              shares: null,
            ),
          );
        }
        continue;
      }
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

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  /// Calculate profile strength percentage
  /// - 20% for at least 1 social media
  /// - 20% for bio text
  /// - 20% for profile picture
  /// - 30% for interests
  /// - 10% for category
  int _calculateProfileStrength(UserDTO user) {
    int strength = 0;

    if (user.socialEcosystem != null && user.socialEcosystem!.isNotEmpty) {
      strength += 20;
    }
    if (user.bio != null && user.bio!.trim().isNotEmpty) {
      strength += 20;
    }
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      strength += 20;
    }
    if (user.interests.isNotEmpty) {
      strength += 30;
    }
    if (user.category != null && user.category!.isNotEmpty) {
      strength += 10;
    }

    return strength;
  }
}

class _InfoCardGlass extends StatelessWidget {
  final Widget child;

  const _InfoCardGlass({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
