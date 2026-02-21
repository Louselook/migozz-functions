import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Social networks footer — social icons + WhatsApp button.
/// Mirrors the React SocialNetworks component.
class SocialNetworksFooter extends StatelessWidget {
  const SocialNetworksFooter({super.key});

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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC238BD), Color(0xFF681C99)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 30,
        horizontal: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: isMobile
              ? Column(
                  children: [
                    _buildSocialIcons(isMobile),
                    const SizedBox(height: 30),
                    _buildWhatsAppButton(isMobile),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcons(isMobile),
                    const SizedBox(width: 40),
                    _buildWhatsAppButton(isMobile),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSocialIcons(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 10 : 15,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _socialLinks.map((social) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openUrl(social.url),
            child: SizedBox(
              width: isMobile ? 40 : 50,
              height: isMobile ? 40 : 50,
              child: SvgPicture.asset(
                social.iconPath,
                width: isMobile ? 40 : 50,
                height: isMobile ? 40 : 50,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWhatsAppButton(bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openUrl('https://whatsapp.com'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 30,
            vertical: isMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF6B218D),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/social_networks/WhatsApp.svg',
                width: isMobile ? 30 : 36,
                height: isMobile ? 30 : 36,
              ),
              const SizedBox(width: 12),
              Text(
                'landing.whatsapp_btn'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 14 : 16,
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
