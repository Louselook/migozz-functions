import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class SocialBarsMobileV2 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialBarsMobileV2({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: links
            .map((link) => _SocialBarItemMobile(link: link))
            .toList(),
      ),
    );
  }
}

class _SocialBarItemMobile extends StatefulWidget {
  final SocialLink link;

  const _SocialBarItemMobile({required this.link});

  @override
  State<_SocialBarItemMobile> createState() => _SocialBarItemMobileState();
}

class _SocialBarItemMobileState extends State<_SocialBarItemMobile> {
  bool _isPressed = false;

  List<Color> _getGradientForSocial(String asset) {
    final assetLower = asset.toLowerCase();

    // TikTok: Gris oscuro
    if (assetLower.contains('tiktok')) {
      return [const Color(0xFF3D3D3D), const Color(0xFF3D3D3D)];
    }

    // Instagram: Rosa a morado
    if (assetLower.contains('instagram')) {
      return [const Color(0xFFE1306C), const Color(0xFF833AB4)];
    }

    // Facebook: Azul a azul cyan
    if (assetLower.contains('facebook')) {
      return [const Color(0xFF1877F2), const Color(0xFF00C6FF)];
    }

    // YouTube: Rojo
    if (assetLower.contains('youtube')) {
      return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
    }

    // Telegram: Azul a cyan
    if (assetLower.contains('telegram')) {
      return [const Color(0xFF0088CC), const Color(0xFF00D4FF)];
    }

    // WhatsApp: Verde
    if (assetLower.contains('whatsapp')) {
      return [const Color(0xFF25D366), const Color(0xFF128C7E)];
    }

    // Twitter: Azul
    if (assetLower.contains('twitter')) {
      return [const Color(0xFF1DA1F2), const Color(0xFF0E71C8)];
    }

    // Pinterest: Rojo
    if (assetLower.contains('pinterest')) {
      return [const Color(0xFFE60023), const Color(0xFFBD001F)];
    }

    // Spotify: Verde
    if (assetLower.contains('spotify')) {
      return [const Color(0xFF1DB954), const Color(0xFF1ED760)];
    }

    // LinkedIn: Azul
    if (assetLower.contains('linkedin')) {
      return [const Color(0xFF0077B5), const Color(0xFF00A0DC)];
    }

    // Default: Morado
    return [const Color(0xFF8B5CF6), const Color(0xFF6B21A8)];
  }

  String _getPlatformName(String asset) {
    final assetLower = asset.toLowerCase();
    if (assetLower.contains('tiktok')) return 'TikTok';
    if (assetLower.contains('instagram')) return 'Instagram';
    if (assetLower.contains('twitter')) return 'X';
    if (assetLower.contains('facebook')) return 'Facebook';
    if (assetLower.contains('pinterest')) return 'Pinterest';
    if (assetLower.contains('youtube')) return 'YouTube';
    if (assetLower.contains('telegram')) return 'Telegram';
    if (assetLower.contains('whatsapp')) return 'WhatsApp';
    if (assetLower.contains('spotify')) return 'Spotify';
    if (assetLower.contains('linkedin')) return 'LinkedIn';
    return 'Social';
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(
      widget.link.url,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch ${widget.link.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientForSocial(widget.link.asset);
    final platformName = _getPlatformName(widget.link.asset);
    const iconSize = 24.0;
    const barHeight = 50.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _launchUrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? gradientColors[0].withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          transform: _isPressed
              ? Matrix4.translationValues(0, 2, 0)
              : Matrix4.identity(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nombre de la plataforma (centrado)
                Expanded(
                  child: Text(
                    platformName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Ícono de la red social al final (derecha)
                Container(
                  width: iconSize + 10,
                  height: iconSize + 10,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    widget.link.asset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
