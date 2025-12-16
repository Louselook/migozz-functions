import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:http/http.dart' as http;

final Map<String, Uint8List?> _svgMemoryCache = {};

class SocialCirclesMobileV3 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialCirclesMobileV3({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final spacing = 1.0;
    final iconSize = 28.0;

    // Separar redes sociales de URLs personalizadas
    final socialNetworks = <SocialLink>[];

    for (final link in links) {
      final assetLower = link.asset.toLowerCase();
      if (!assetLower.contains('other') &&
          !assetLower.contains('paypal') &&
          !assetLower.contains('xbox')) {
        socialNetworks.add(link);
      }
    }

    if (socialNetworks.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: iconSize + 8,
      child: Center(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: socialNetworks.length,
          separatorBuilder: (context, index) => SizedBox(width: spacing),
          itemBuilder: (context, index) {
            return _SocialBoxItem(
              link: socialNetworks[index],
              boxSize: iconSize,
            );
          },
        ),
      ),
    );
  }
}

Future<Uint8List?> _fetchBytes(String url) async {
  if (_svgMemoryCache.containsKey(url)) {
    return _svgMemoryCache[url];
  }
  try {
    final uri = Uri.parse(url);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      _svgMemoryCache[url] = res.bodyBytes;
      return res.bodyBytes;
    }
  } catch (_) {}
  return null;
}

class SocialCirclesMobileV3Edit extends StatelessWidget {
  final List<SocialLink> links;
  final VoidCallback? onAddPressed;

  const SocialCirclesMobileV3Edit({
    super.key,
    required this.links,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = 1.0;
    final iconSize = 28.0;

    // Separar redes sociales de URLs personalizadas
    final socialNetworks = <SocialLink>[];

    for (final link in links) {
      final assetLower = link.asset.toLowerCase();
      if (!assetLower.contains('other') &&
          !assetLower.contains('paypal') &&
          !assetLower.contains('xbox')) {
        socialNetworks.add(link);
      }
    }

    return SizedBox(
      height: iconSize + 8,
      child: Center(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: socialNetworks.length + 1, // +1 for add button
          separatorBuilder: (context, index) => SizedBox(width: spacing),
          itemBuilder: (context, index) {
            // First item is the add button
            if (index == 0) {
              return _AddSocialButton(
                iconSize: iconSize,
                onPressed: onAddPressed,
              );
            }

            // Other items are social links
            return _SocialBoxItem(
              link: socialNetworks[index - 1],
              boxSize: iconSize,
            );
          },
        ),
      ),
    );
  }
}

class _AddSocialButton extends StatelessWidget {
  final double iconSize;
  final VoidCallback? onPressed;

  const _AddSocialButton({required this.iconSize, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.verticalPinkPurple,
        ),
        child: Center(
          child: Icon(Icons.add, color: Colors.white, size: iconSize * 0.6),
        ),
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
    return GestureDetector(onTap: _launchUrl, child: _buildIcon());
  }
}

Widget _buildNetworkSvg(String url, double size) {
  return FutureBuilder<Uint8List?>(
    future: _fetchBytes(url),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _placeholderIcon(size);
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return _placeholderIcon(size);
      }
      return _socialIconCircle(
        SvgPicture.memory(
          bytes,
          width: size * 0.7,
          height: size * 0.7,
          fit: BoxFit.contain,
        ),
        size,
      );
    },
  );
}

Widget _buildAssetSvg(String asset, double size) {
  return _socialIconCircle(
    SvgPicture.asset(
      asset,
      width: size * 0.7,
      height: size * 0.7,
      fit: BoxFit.contain,
    ),
    size,
  );
}

Widget _buildRasterNetwork(String url, double size) {
  return _socialIconCircle(
    ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            Icon(Icons.language, color: Colors.white, size: size * 0.7),
      ),
    ),
    size,
  );
}

extension on _SocialBoxItemState {
  Widget _buildIcon() {
    final asset = widget.link.asset;
    final size = widget.boxSize;
    final isNetwork =
        asset.startsWith('http://') || asset.startsWith('https://');
    final isSvg = asset.toLowerCase().endsWith('.svg');
    if (isNetwork) {
      return isSvg
          ? _buildNetworkSvg(asset, size)
          : _buildRasterNetwork(asset, size);
    }
    return _buildAssetSvg(asset, size);
  }
}

Widget _socialIconCircle(Widget child, double size) {
  return Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.12),

    child: Center(child: child),
  );
}

Widget _placeholderIcon(double size) {
  return _socialIconCircle(
    Icon(Icons.language, color: Colors.white, size: size * 0.7),
    size,
  );
}
