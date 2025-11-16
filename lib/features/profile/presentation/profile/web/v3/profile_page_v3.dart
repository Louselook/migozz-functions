import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/profile_version_button.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_background_gradients.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_search_button.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/profile_header_v3.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/social_circles_v3.dart';

class WebProfileContentV3 extends StatelessWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;

  const WebProfileContentV3({
    super.key,
    required this.user,
    required this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    // Calcular seguidores totales desde socialEcosystem
    final totalFollowers = _calculateTotalFollowers(user.socialEcosystem);

    // Construir enlaces de redes sociales
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 360,
            maxWidth: double.infinity,
          ),
          child: Stack(
            children: [
              // Fondo con gradientes
              const ProfileBackgroundGradients(),

              // Contenido principal con scroll
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(left: leftMenuWidth),
                  child: CustomScrollView(
                    slivers: [
                      // Header con avatar y nombre
                      SliverToBoxAdapter(
                        child: Builder(
                          builder: (context) {
                            final authState = context.read<AuthCubit>().state;
                            final currentUserEmail =
                                authState.userProfile?.email ?? '';
                            final isOwnProfile = user.email == currentUserEmail;

                            return ProfileHeaderV3(
                              name: user.displayName,
                              displayName: user.username,
                              communityCount: totalFollowers.toString(),
                              communityName: 'Community',
                              avatarUrl: user.avatarUrl,
                              voiceNoteUrl: user.voiceNoteUrl ?? '',
                              tutorialKeys: tutorialKeys,
                              isOwnProfile: isOwnProfile,
                              userId: user.email,
                            );
                          },
                        ),
                      ),

                      // Iconos circulares de redes sociales (versión 3)
                      SliverToBoxAdapter(
                        child: Center(
                          child: SocialCirclesV3(links: socialLinks),
                        ),
                      ),

                      // Espacio para futuras publicaciones u otro contenido
                      SliverToBoxAdapter(
                        child: SizedBox(height: isSmallScreen ? 40 : 60),
                      ),
                    ],
                  ),
                ),
              ),

              // Menú lateral izquierdo (se mantiene igual)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SideMenu(tutorialKeys: tutorialKeys),
              ),

              // Botón de búsqueda (se mantiene igual)
              ProfileSearchButton(key: tutorialKeys.searchScreenKey),

              // Botón para cambiar versión de perfil
              ProfileVersionButton(currentVersion: user.profileVersion),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // 🔢 Calcular total de seguidores
  // ===============================
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

  // ===============================
  // 🔗 Construir enlaces de redes
  // ===============================
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

  // ===============================
  // 🧭 Generar URL + ícono por red
  // ===============================
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
}
