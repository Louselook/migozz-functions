import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';

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
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    // Build social links for the V3 social circles component
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

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
                        child: Container(
                          color: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Avatar background
                              if (user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty)
                                Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[900]),
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [Color(0xFF9036c4), Colors.black],
                                      radius: 1.2,
                                    ),
                                  ),
                                ),

                              // Dark Overlay gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.9),
                                    ],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),

                              // Content in Left Panel
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Name
                                    Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName
                                          : user.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '@${user.username}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Social Circles
                                    SocialCirclesMobileV3(links: socialLinks),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),

                              // Back Button
                              Positioned(
                                top: 20,
                                left: 20,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            ],
                          ),
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
                                // Bio Section
                                if (user.bio != null &&
                                    user.bio!.trim().isNotEmpty)
                                  _buildSection(
                                    title: 'profile.customization.bio.label'
                                        .tr(),
                                    child: Text(
                                      user.bio!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),

                                // Featured Links
                                if (user.featuredLinks != null &&
                                    user.featuredLinks!.isNotEmpty)
                                  _buildSection(
                                    title: 'profile.customization.links.label'
                                        .tr(),
                                    child: Column(
                                      children: user.featuredLinks!.map((link) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _FeaturedLinkTile(link: link),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                // Contact Info
                                if (_hasContactInfo(user))
                                  _buildSection(
                                    title: 'profile.customization.contact.label'
                                        .tr(),
                                    child: Column(
                                      children: [
                                        if (user.contactEmail != null &&
                                            user.contactEmail!.isNotEmpty)
                                          _ContactTile(
                                            icon: Icons.email_outlined,
                                            value: user.contactEmail!,
                                            onTap: () => _launchUri(
                                              Uri(
                                                scheme: 'mailto',
                                                path: user.contactEmail,
                                              ),
                                            ),
                                          ),
                                        if (user.contactWebsite != null &&
                                            user.contactWebsite!.isNotEmpty)
                                          _ContactTile(
                                            icon: Icons.language,
                                            value: user.contactWebsite!,
                                            onTap: () => _launchUri(
                                              Uri.parse(
                                                user.contactWebsite!.startsWith(
                                                      'http',
                                                    )
                                                    ? user.contactWebsite!
                                                    : 'https://${user.contactWebsite}',
                                              ),
                                            ),
                                          ),
                                        if (user.contactPhone != null &&
                                            user.contactPhone!.isNotEmpty)
                                          _ContactTile(
                                            icon: Icons.phone_outlined,
                                            value: user.contactPhone!,
                                            onTap:
                                                () {}, // Phone launching might depend on device
                                          ),
                                      ],
                                    ),
                                  ),

                                // Interests
                                if (user.interests.isNotEmpty)
                                  _buildSection(
                                    title:
                                        'profile.customization.interests.label'
                                            .tr(),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: user.interests.values
                                          .expand((e) => e)
                                          .map((interest) {
                                            return Chip(
                                              label: Text(
                                                interest,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),

                                const SizedBox(height: 100),
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

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        child,
        const SizedBox(height: 40),
      ],
    );
  }

  bool _hasContactInfo(UserDTO user) =>
      (user.contactWebsite != null && user.contactWebsite!.isNotEmpty) ||
      (user.contactPhone != null && user.contactPhone!.isNotEmpty) ||
      (user.contactEmail != null && user.contactEmail!.isNotEmpty);

  Future<void> _launchUri(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URI: $e');
    }
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

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=\$domain&sz=128';
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
        url = customUrl ?? 'https://www.tiktok.com/@\$username';
        break;
      case 'instagram':
        url = customUrl ?? 'https://www.instagram.com/\$username';
        break;
      case 'x':
      case 'twitter':
        url = customUrl ?? 'https://x.com/\$username';
        break;
      case 'facebook':
        url = customUrl ?? 'https://www.facebook.com/\$username';
        break;
      case 'pinterest':
        url = customUrl ?? 'https://www.pinterest.com/\$username';
        break;
      case 'youtube':
        url = customUrl ?? 'https://www.youtube.com/@\$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/\$username';
        break;
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/\$username';
        break;
      case 'spotify':
        url = customUrl ?? 'https://open.spotify.com/user/\$username';
        break;
      case 'linkedin':
        url = customUrl ?? 'https://www.linkedin.com/in/\$username';
        break;
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}

class _FeaturedLinkTile extends StatelessWidget {
  final Map<String, dynamic> link;

  const _FeaturedLinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    final title = link['title'] ?? '';
    final url = link['url'] ?? '';

    return DataContainer(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url.startsWith('http') ? url : 'https://\$url');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (url.isNotEmpty)
                    Text(
                      url,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
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
