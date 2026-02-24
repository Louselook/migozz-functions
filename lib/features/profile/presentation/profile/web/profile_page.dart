import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/profile_version_button.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_background_gradients.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_header.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_search_button.dart';
// import 'package:migozz_app/features/profile/presentation/profile/web/components/publications_content.dart';

class WebProfileContent extends StatelessWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;
  const WebProfileContent({
    super.key,
    required this.user,
    required this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final socialItemSize = isSmallScreen ? 35.0 : 45.0;
    final socialIconSize = isSmallScreen ? 30.0 : 40.0;
    final socialRailWidth = socialItemSize + 16;
    final socialPadding = isSmallScreen ? 20.0 : 30.0;
    final socialRailHeight = (socialItemSize * 4) + (8.0 * 3) + 16.0;
    final initialSocialPosition = Offset(
      size.width - socialRailWidth - socialPadding,
      (size.height - socialRailHeight) / 2,
    );
    final isMediumScreen = size.width >= 600 && size.width < 1200;
    final leftMenuWidth = isSmallScreen
        ? 60.0
        : isMediumScreen
        ? 70.0
        : 80.0;

    // Calcular seguidores totales desde socialEcosystem
    final totalFollowers = _calculateTotalFollowers(user.socialEcosystem);

    // Construir enlaces de redes sociales
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

    // Pasa info real del user al ProfileHeader (adapta ProfileHeader para aceptar params)
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
              const ProfileBackgroundGradients(),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(left: leftMenuWidth),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Builder(
                          builder: (context) {
                            // Determinar si es el perfil del usuario autenticado
                            final authState = context.read<AuthCubit>().state;
                            final currentUserEmail =
                                authState.userProfile?.email ?? '';
                            final isOwnProfile = user.email == currentUserEmail;

                            return ProfileHeader(
                              name: user.displayName,
                              displayName: user.username,
                              communityCount: totalFollowers.toString(),
                              communityName: 'profile.presentation.community'
                                  .tr(),
                              avatarUrl: user.avatarUrl,
                              voiceNoteUrl: user.voiceNoteUrl ?? '',
                              tutorialKeys: tutorialKeys,
                              isOwnProfile: isOwnProfile,
                              userId: user.email,
                            );
                          },
                        ),
                      ),
                      // const SliverFillRemaining(child: PublicationsContent()),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SideMenu(tutorialKeys: tutorialKeys),
              ),
              // Assign tutorial key so the tutorial can target this button
              ProfileSearchButton(key: tutorialKeys.searchScreenKey),
              DraggableSocialRail(
                key: ValueKey('social_rail_${size.width}'),
                initialPosition: initialSocialPosition,
                links: socialLinks,
                itemSize: socialItemSize,
                iconSize: socialIconSize,
              ),
              // Botón para cambiar versión de perfil
              ProfileVersionButton(currentVersion: user.profileVersion),
            ],
          ),
        ),
      ),
    );
  }

  // Calcular total de seguidores

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
