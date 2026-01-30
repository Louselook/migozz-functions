import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileInfoPanel extends StatelessWidget {
  final UserDTO user;
  final List<SocialLink> socialLinks;
  final String communityCount;
  final bool isOwnProfile;

  final int unreadCount;
  final VoidCallback? onNotificationTap;

  const ProfileInfoPanel({
    super.key,
    required this.user,
    required this.socialLinks,
    required this.communityCount,
    this.isOwnProfile = false,
    this.unreadCount = 0,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine image source
    final String? avatarUrl = user.avatarUrl;
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    const String fallbackAsset = 'assets/images/avatar.webp';

    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- BACKGROUND LAYER ---
          // If real avatar: show it full cover.
          // If no avatar: use the new 'Purple Gradient' background requested in uploaded_media_2
          if (hasAvatar)
            Positioned.fill(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2), // Slightly above center
                    radius: 1.2,
                    colors: [
                      Color(0xFF9036c4), // Vibrant purple center
                      Color(0xFF531175), // Deep purple mid
                      Color(0xFF1a0526), // Dark purple edge
                      Colors.black, // Fade into black
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // --- HERO IMAGE LAYER (Fallback only) ---
          // If no real avatar, we show the fallback asset (silhouette) as a large hero image rising from bottom.
          // This matches uploaded_media_2.
          if (!hasAvatar)
            Positioned.fill(
              bottom: 150, // Leave space for text
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.7, // Take up 70% of width?
                  // No, let's just make it a big image
                  child: Image.asset(
                    fallbackAsset,
                    fit: BoxFit.contain,
                    // Add simple shadow/glow behind silhouette if png is transparent
                  ),
                ),
              ),
            ),

          // --- OVERLAY LAYER ---
          // Gradient to ensure text is readable (Black fading up)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 1.0),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // --- CONTENT LAYER ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name & Handle
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Community & Share Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          communityCount,
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'profile.presentation.community'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.send_outlined, color: Colors.white, size: 24),
                  ],
                ),

                const SizedBox(height: 24),

                // Bio Box
                if (user.bio != null && user.bio!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.headphones,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            user.bio!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Social Icons Row
                SizedBox(
                  height: 40,
                  child: Center(
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: socialLinks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final link = socialLinks[index];
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              link.url,
                              mode: LaunchMode.externalApplication,
                            ),
                            child: SvgPicture.asset(
                              link.asset,
                              width: 32,
                              height: 32,
                              // No color filter, showing original
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bell Icon Top Left
          Positioned(
            top: 40,
            left: 24,
            child: GestureDetector(
              onTap: onNotificationTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 32,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0050),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
