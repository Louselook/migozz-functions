// lib/features/profile/components/social_rail.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLink {
  final String asset; // ruta del icono (svg/png)
  final Uri url; // enlace de la red
  const SocialLink({required this.asset, required this.url});
}

class SocialRail extends StatelessWidget {
  final List<SocialLink> links;
  final double itemSize; // tamaño del “botoncito” circular de cada icono
  final double iconSize; // tamaño del gráfico dentro del botón

  const SocialRail({
    super.key,
    required this.links,
    this.itemSize = 80,
    this.iconSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 10),

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.35),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.35),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < links.length; i++) ...[
                _SocialButton(
                  link: links[i],
                  size: itemSize,
                  iconSize: iconSize,
                ),
                if (i != links.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final SocialLink link;
  final double size;
  final double iconSize;

  const _SocialButton({
    required this.link,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => {
          launchUrl(link.url, mode: LaunchMode.externalApplication),
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: _buildIcon(link.asset, iconSize)),
        ),
      ),
    );
  }

  Widget _buildIcon(String asset, double size) {
    final isSvg = asset.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        asset,
        width: 35,
        height: 35,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(asset, width: 35, height: 35, fit: BoxFit.contain);
  }
}
