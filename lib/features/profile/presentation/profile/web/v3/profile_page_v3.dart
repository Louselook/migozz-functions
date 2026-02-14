import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/core/components/atomics/web_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/components/profile_info_panel.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

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
    final isMobileWidth = size.width < 600;
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    // Build social links for the V3 social circles component
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

    // ── Mobile-like layout for narrow screens ──
    if (isMobileWidth) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Builder(
          builder: (context) {
            final authState = context.watch<AuthCubit>().state;
            final currentUser = authState.userProfile;
            final isOwn = currentUser?.username == user.username;
            final totalFollowers = socialLinks.fold<int>(
              0,
              (sum, link) => sum + (link.followers ?? 0),
            );

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile info panel — takes ~55% of screen height
                  SizedBox(
                    height: size.height * 0.65,
                    child: ProfileInfoPanel(
                      user: user,
                      socialLinks: socialLinks,
                      communityCount: totalFollowers.toString(),
                      isOwnProfile: isOwn,
                      currentUserId: currentUser?.email,
                      targetUserId: user.email,
                      isMobileLayout: true,
                    ),
                  ),

                  // Social Highlights below
                  if (socialLinks.any(
                    (link) =>
                        link.profileImageUrl != null &&
                        link.profileImageUrl!.isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: _SocialHighlightsSection(links: socialLinks),
                    ),

                  // Bottom spacing for bottom nav bar
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      );
    }

    // ── Desktop/tablet two-column layout ──
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: leftMenuWidth), // Spacer for side menu

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Profile Preview (Avatar + Socials)
                      Expanded(
                        flex: 5,
                        child: Builder(
                          builder: (context) {
                            final authState = context.watch<AuthCubit>().state;
                            final currentUser = authState.userProfile;
                            final isOwn =
                                currentUser?.username == user.username;

                            final totalFollowers = socialLinks.fold<int>(
                              0,
                              (sum, link) => sum + (link.followers ?? 0),
                            );

                            return ProfileInfoPanel(
                              user: user,
                              socialLinks: socialLinks,
                              communityCount: totalFollowers.toString(),
                              isOwnProfile: isOwn,
                              currentUserId: currentUser?.email,
                              targetUserId: user.email,
                            );
                          },
                        ),
                      ),

                      // Right Panel: Details (Bio, Links, etc.)
                      Expanded(
                        flex: 7,
                        child: Container(
                          color: const Color(0xFF0A0A0A),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Social Highlights (New)
                                if (socialLinks.any(
                                  (link) =>
                                      link.profileImageUrl != null &&
                                      link.profileImageUrl!.isNotEmpty,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 40),
                                    child: _SocialHighlightsSection(
                                      links: socialLinks,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side Menu Overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftMenuWidth,
            child: SideMenu(tutorialKeys: tutorialKeys),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods for Social Links (Copied/Adapted from Edit) ---

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
        String? profileImageUrl;

        if (data is Map<String, dynamic>) {
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();
          profileImageUrl =
              data['profileImageUrl']?.toString() ??
              data['profile_image_url']?.toString() ??
              data['imageUrl']?.toString() ??
              data['avatar']?.toString();
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

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
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
}

class _SocialHighlightsSection extends StatelessWidget {
  final List<SocialLink> links;

  const _SocialHighlightsSection({required this.links});

  @override
  Widget build(BuildContext context) {
    // Filter links with images
    final imageLinks = links
        .where(
          (l) => l.profileImageUrl != null && l.profileImageUrl!.isNotEmpty,
        )
        .toList();

    if (imageLinks.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: imageLinks
          .map((link) => _HighlightCard(link: link))
          .toList(),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final SocialLink link;

  const _HighlightCard({required this.link});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileWidth = screenWidth < 600;
    final cardWidth = isMobileWidth ? (screenWidth - 48) : 320.0; // 48 = padding

    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(link.url)) {
          await launchUrl(link.url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: cardWidth,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image Layer
            // Image Layer
            Positioned.fill(
              child: WebNetworkImage(
                imageUrl: link.profileImageUrl!,
                fit: BoxFit.cover,
                borderRadius: 16,
                errorWidget: Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            ),
            // Dark Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Social Icon
            Positioned(right: 12, bottom: 12, child: _buildIcon(link.asset)),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String asset) {
    // Check if asset is URL or local SVG
    if (asset.startsWith('http')) {
      return SizedBox(
        width: 28,
        height: 28,
        child: WebNetworkImage(
          imageUrl: asset,
          fit: BoxFit.contain,
          errorWidget: const Icon(Icons.link, color: Colors.white),
        ),
      );
    }
    return SvgPicture.asset(asset, width: 28, height: 28);
  }
}

class DataContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DataContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
