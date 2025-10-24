import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/Components/profile_background_gradients.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_header.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_search_button.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/publications_content.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/utils/side_menu.dart';

class WebProfileContent extends StatelessWidget {
  final UserDTO user;
  const WebProfileContent({super.key, required this.user});

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
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

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
                        child: ProfileHeader(
                          name: user.displayName,
                          displayName: user.username,
                          communityCount:
                              '—', // calcula si tu user trae followers
                          communityName: 'Community',
                          imageAsset:
                              user.avatarUrl ?? 'assets/img/ImgPefil.webp',
                        ),
                      ),
                      const SliverFillRemaining(child: PublicationsContent()),
                    ],
                  ),
                ),
              ),
              const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),
              const ProfileSearchButton(),
              DraggableSocialRail(
                key: ValueKey('social_rail_${size.width}'),
                initialPosition: initialSocialPosition,
                links: [
                  // construye desde user.socialEcosystem o deja placeholders
                ],
                itemSize: socialItemSize,
                iconSize: socialIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
