import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class SocialBarsV2 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialBarsV2({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final maxWidth = isSmallScreen ? size.width * 0.8 : 500.0;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: links
            .map(
              (link) =>
                  _SocialBarItem(link: link, isSmallScreen: isSmallScreen),
            )
            .toList(),
      ),
    );
  }
}

class _SocialBarItem extends StatefulWidget {
  final SocialLink link;
  final bool isSmallScreen;

  const _SocialBarItem({required this.link, required this.isSmallScreen});

  @override
  State<_SocialBarItem> createState() => _SocialBarItemState();
}

class _SocialBarItemState extends State<_SocialBarItem> {
  bool _isHovered = false;

  List<Color> _getGradientForSocial(String asset) {
    final assetLower = asset.toLowerCase();

    // TikTok: Rosa oscuro a gris oscuro
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
    final iconSize = widget.isSmallScreen ? 24.0 : 28.0;
    final barHeight = widget.isSmallScreen ? 50.0 : 60.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _launchUrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? gradientColors[0].withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: _isHovered ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nombre de la plataforma (centrado)
                  Expanded(
                    child: Text(
                      platformName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Ícono de la red social al final (derecha)
                  Container(
                    width: iconSize + 12,
                    height: iconSize + 12,
                    padding: const EdgeInsets.all(6),
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
      ),
    );
  }
}
