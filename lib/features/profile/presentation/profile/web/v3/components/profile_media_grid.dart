import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class ProfileMediaGrid extends StatelessWidget {
  final List<SocialLink> socialLinks;
  final List<Map<String, dynamic>>? rawSocialData;
  final bool scrollingEnabled;

  const ProfileMediaGrid({
    super.key,
    required this.socialLinks,
    this.rawSocialData,
    this.scrollingEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) {
      return Center(
        child: Text(
          "No linked accounts",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    // Get screen width to determine column count
    final width = MediaQuery.of(context).size.width;
    // Mobile (<600): 2 cols. Tablet/Desktop: 3 cols (per "smaller" request)
    // Actually, the sketch shows 2 cols even on desktop roughly. But "smaller" likely means denser.
    // Let's go with 3 columns on larger screens to make them smaller.
    final int crossAxisCount = width > 900 ? 3 : 2;

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: socialLinks.length,
        physics: scrollingEnabled
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        shrinkWrap: !scrollingEnabled,
        itemBuilder: (context, index) {
          final link = socialLinks[index];
          return _SocialMediaCard(link: link, index: index);
        },
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  final SocialLink link;
  final int index;

  const _SocialMediaCard({required this.link, required this.index});

  @override
  Widget build(BuildContext context) {
    // Reduce heights to make them "smaller"
    // Old: 300, 250, 200. New: 220, 180, 150.
    final double height = (index % 3 == 0)
        ? 220
        : ((index % 2 == 0) ? 150 : 180);

    // Determine the image to show.
    // 1. If SocialLink has a profileImageUrl, use it.
    // 2. Fallback to asset avatar if not.
    // "si no tiene, esa imagen esta perfecta (assets/images/avatar.webp)"

    final hasProfileImage =
        link.profileImageUrl != null && link.profileImageUrl!.isNotEmpty;
    final imageProvider = hasProfileImage
        ? NetworkImage(link.profileImageUrl!)
        : const AssetImage('assets/images/avatar.webp') as ImageProvider;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          opacity:
              0.8, // Slight opacity to make it look cool? Or full. User said "traer la imagen de perfil". Full is better.
        ),
      ),
      child: Stack(
        children: [
          // If using full opacity, we might need a gradient at bottom for the icon visibility?
          // But the icon has a bubble background, so it's fine.
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                link.asset,
                width: 16, // Smaller icon
                height: 16,
                // Original color or white? Sketch shows coloured icon (Insta).
                // Let's keep original colors (no filter).
              ),
            ),
          ),
        ],
      ),
    );
  }
}
