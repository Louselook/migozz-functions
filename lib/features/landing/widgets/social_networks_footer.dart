import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Social networks footer — social icons + WhatsApp button.
/// Updated design inspired by landing_page2.
class SocialNetworksFooter extends StatelessWidget {
  const SocialNetworksFooter({super.key});

  static const _hotPink = Color(0xFFE91E8B);
  static const _deepPurple = Color(0xFF7B1FA2);

  static const _socialLinks = [
    _SocialLink(
      'TikTok',
      'assets/icons/social_networks/Tiktok.svg',
      'https://www.tiktok.com/@migozzoficial',
    ),
    _SocialLink(
      'Instagram',
      'assets/icons/social_networks/Instagram.svg',
      'https://www.instagram.com/migozzofficial/',
    ),
    _SocialLink(
      'Facebook',
      'assets/icons/social_networks/Facebook.svg',
      'https://www.facebook.com/profile.php?id=61581724792864',
    ),
    _SocialLink(
      'YouTube',
      'assets/icons/social_networks/Youtube.svg',
      'https://www.youtube.com/@migozzoficial',
    ),
  ];

  static const _whatsAppUrl =
      'https://whatsapp.com/channel/0029VbBjViR9cDDRkiw8Wj3C';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 500;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_hotPink, _deepPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 32,
        horizontal: isMobile ? 16 : 24,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildSocialIcons(),
                const SizedBox(height: 16),
                _buildWhatsAppButton(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcons(),
                const SizedBox(width: 32),
                _buildWhatsAppButton(),
              ],
            ),
    );
  }

  Widget _buildSocialIcons() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _socialLinks.map((social) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openUrl(social.url),
            child: SizedBox(
              width: 36,
              height: 36,
              child: SvgPicture.asset(social.iconPath, width: 36, height: 36),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWhatsAppButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openUrl(_whatsAppUrl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/social_networks/WhatsApp.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'landing.whatsapp_btn'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Bebas Neue',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLink {
  final String name;
  final String iconPath;
  final String url;

  const _SocialLink(this.name, this.iconPath, this.url);
}
