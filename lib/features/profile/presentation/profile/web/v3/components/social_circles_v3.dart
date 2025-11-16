import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class SocialCirclesV3 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialCirclesV3({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    final boxSize = isSmallScreen ? 80.0 : 95.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;
    final maxWidth = isSmallScreen ? size.width * 0.9 : 600.0;

    // Separar redes sociales de URLs personalizadas
    final socialNetworks = <SocialLink>[];
    final customLinks = <SocialLink>[];

    for (final link in links) {
      final assetLower = link.asset.toLowerCase();
      if (assetLower.contains('other') ||
          assetLower.contains('paypal') ||
          assetLower.contains('xbox')) {
        customLinks.add(link);
      } else {
        socialNetworks.add(link);
      }
    }

    // Si no hay enlaces personalizados, agregar ejemplos
    final displayCustomLinks = customLinks.isNotEmpty
        ? customLinks
        : [
            SocialLink(
              asset: 'assets/icons/social_networks/other.svg',
              url: Uri.parse('https://www.taylorconcert.com'),
            ),
            SocialLink(
              asset: 'assets/icons/social_networks/other.svg',
              url: Uri.parse('https://mystore.example.com'),
            ),
          ];

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
        vertical: 20,
      ),
      child: Column(
        children: [
          // Redes sociales en grid
          Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: socialNetworks
                .map((link) => _SocialBoxItem(link: link, boxSize: boxSize))
                .toList(),
          ),

          // Espaciado entre secciones
          const SizedBox(height: 20),

          // Enlaces personalizados (website, etc.)
          ...displayCustomLinks
              .map(
                (link) =>
                    _CustomLinkButton(link: link, isSmallScreen: isSmallScreen),
              )
              .toList(),
        ],
      ),
    );
  }
}

class _SocialBoxItem extends StatefulWidget {
  final SocialLink link;
  final double boxSize;

  const _SocialBoxItem({required this.link, required this.boxSize});

  @override
  State<_SocialBoxItem> createState() => _SocialBoxItemState();
}

class _SocialBoxItemState extends State<_SocialBoxItem> {
  bool _isHovered = false;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _launchUrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.boxSize,
          height: widget.boxSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF581d4f),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              // Sombra externa
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: _isHovered ? 15 : 10,
                offset: const Offset(0, 4),
              ),
              // Sombra interna para profundidad
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
          transform: _isHovered
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          child: Center(
            child: SvgPicture.asset(
              widget.link.asset,
              width: widget.boxSize * 0.5,
              height: widget.boxSize * 0.5,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomLinkButton extends StatefulWidget {
  final SocialLink link;
  final bool isSmallScreen;

  const _CustomLinkButton({required this.link, required this.isSmallScreen});

  @override
  State<_CustomLinkButton> createState() => _CustomLinkButtonState();
}

class _CustomLinkButtonState extends State<_CustomLinkButton> {
  bool _isHovered = false;

  Future<void> _launchUrl() async {
    if (!await launchUrl(
      widget.link.url,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch ${widget.link.url}');
    }
  }

  String _getButtonText() {
    final url = widget.link.url.toString();
    if (url.contains('taylorconcert.com')) {
      return 'www.taylorconcert.com';
    }
    if (url.contains('store') || url.contains('shop')) {
      return 'Visit my online store';
    }
    // Extraer dominio de la URL
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return 'Visit website';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _launchUrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFF581d4f),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                // Sombra externa
                BoxShadow(
                  color: _isHovered
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
                // Sombra interna para profundidad
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _getButtonText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: widget.isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.link,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
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
