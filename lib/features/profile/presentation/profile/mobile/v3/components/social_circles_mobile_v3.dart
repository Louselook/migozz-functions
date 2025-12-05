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

    // Calcular número de filas
    final rows = (socialNetworks.length / 3).ceil();

    return Column(
      children: [
        // Grid de redes sociales 3x2
        ...List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * 3;
          final endIndex = (startIndex + 3).clamp(0, socialNetworks.length);
          final rowItems = socialNetworks.sublist(startIndex, endIndex);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rowItems.length; i++) ...[
                _SocialBoxItem(link: rowItems[i], boxSize: boxSize),
                if (i < rowItems.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        }),
      ],
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
    return GestureDetector(
      onTap: _launchUrl,
      child: Center(
        child: SvgPicture.asset(
          widget.link.asset,
          width: widget.boxSize * 0.55,
          height: widget.boxSize * 0.55,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
