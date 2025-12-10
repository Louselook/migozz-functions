import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class SocialCirclesMobileV3 extends StatelessWidget {
  final List<SocialLink> links;

  const SocialCirclesMobileV3({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final spacing = 6.0;
    final iconSize = 24.0;

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
    final spacing = 6.0;
    final iconSize = 24.0;

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
        width: iconSize,
        height: iconSize,
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
    return GestureDetector(
      onTap: _launchUrl,
      child: SvgPicture.asset(
        widget.link.asset,
        width: widget.boxSize,
        height: widget.boxSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
