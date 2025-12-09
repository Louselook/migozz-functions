import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

import '../../../../../../../core/color.dart';

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
    final itemsPerRow = 10;
    final rows = (socialNetworks.length / itemsPerRow).ceil();

    return Column(
      children: [
        ...List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * itemsPerRow;
          final endIndex = (startIndex + itemsPerRow).clamp(
            0,
            socialNetworks.length,
          );
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

    // Crear lista de items incluyendo el botón de agregar
    final allItems = [...socialNetworks];

    // Calcular número de filas (incluyendo el botón +)
    final totalItems = allItems.length + 1; // +1 para el botón de agregar
    final rows = (totalItems / 3).ceil();

    return Column(
      children: [
        // Grid de redes sociales con botón de agregar
        ...List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * 3;
          final endIndex = (startIndex + 3).clamp(0, totalItems);
          final itemsInRow = endIndex - startIndex;

          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? spacing : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < itemsInRow; i++) ...[
                  Builder(
                    builder: (context) {
                      final itemIndex = startIndex + i;

                      // Si es el primer item, mostrar el botón de agregar
                      if (itemIndex == 0) {
                        return _AddSocialButton(
                          boxSize: boxSize,
                          onPressed: onAddPressed,
                        );
                      }

                      // Mostrar item normal (ajustar índice porque el botón + está primero)
                      return _SocialBoxItem(
                        link: allItems[itemIndex - 1],
                        boxSize: boxSize,
                      );
                    },
                  ),
                  if (i < itemsInRow - 1) SizedBox(width: spacing),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AddSocialButton extends StatelessWidget {
  final double boxSize;
  final VoidCallback? onPressed;

  const _AddSocialButton({required this.boxSize, this.onPressed});

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
        child: Center(child: Icon(Icons.add, color: Colors.white, size: 15)),
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
      child: Center(
        child: SvgPicture.asset(
          widget.link.asset,
          width: widget.boxSize * 0.35,
          height: widget.boxSize * 0.35,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
