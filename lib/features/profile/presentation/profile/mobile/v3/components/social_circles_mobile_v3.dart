import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class SocialCirclesMobileV3 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialCirclesMobileV3({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 20.0;
    final spacing = 7.0;
    final availableWidth = screenWidth - (horizontalPadding * 8);
    final boxSize = (availableWidth - (spacing * 3)) / 3;

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

    // Calcular número de filas
    final rows = (socialNetworks.length / 3).ceil();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20,
      ),
      child: Column(
        children: [
          // Grid de redes sociales 3x2
          ...List.generate(rows, (rowIndex) {
            final startIndex = rowIndex * 3;
            final endIndex = (startIndex + 3).clamp(0, socialNetworks.length);
            final rowItems = socialNetworks.sublist(startIndex, endIndex);

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < rows - 1 ? spacing : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < rowItems.length; i++) ...[
                    _SocialBoxItem(link: rowItems[i], boxSize: boxSize),
                    if (i < rowItems.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            );
          }),

          // Espaciado entre secciones
          const SizedBox(height: 20),

          // Enlaces personalizados (website, etc.)
          ...displayCustomLinks
              .map((link) => _CustomLinkButton(link: link)),
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
  bool _isPressed = false;

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
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _launchUrl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
              color: _isPressed
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: _isPressed ? 8 : 10,
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
        transform: _isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        child: Center(
          child: SvgPicture.asset(
            widget.link.asset,
            width: widget.boxSize * 0.55,
            height: widget.boxSize * 0.55,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CustomLinkButton extends StatefulWidget {
  final SocialLink link;

  const _CustomLinkButton({required this.link});

  @override
  State<_CustomLinkButton> createState() => _CustomLinkButtonState();
}

class _CustomLinkButtonState extends State<_CustomLinkButton> {
  bool _isPressed = false;

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
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _launchUrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
                color: _isPressed
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: _isPressed ? 6 : 8,
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
          transform: _isPressed
              ? Matrix4.translationValues(0, 2, 0)
              : Matrix4.identity(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _getButtonText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
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
    );
  }
}
