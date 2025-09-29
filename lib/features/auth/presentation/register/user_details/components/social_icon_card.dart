import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/core/color.dart';

class SocialIconCard extends StatelessWidget {
  final String label;
  final String? assetPath;
  final VoidCallback? onTap;
  final Size? sizeIcon;
  final bool isSelected;
  final double iconSize; // Tamaño específico del icono interno

  const SocialIconCard({
    super.key,
    required this.label,
    this.assetPath,
    this.onTap,
    this.sizeIcon,
    this.iconSize = 40.0, // Valor por defecto para el icono
    this.isSelected = false,
  });

  bool get _isSvg => (assetPath ?? '').toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    // Usar utilidades responsive
    final scaleFactor = context.scaleFactor;
    final responsiveBorderRadius = ResponsiveUtils.scaleValue(
      15.0,
      scaleFactor,
      minValue: 12.0,
      maxValue: 20.0,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: sizeIcon?.width ?? 65,
        height: sizeIcon?.height ?? 65,
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.primaryGradient : null, 
          color: isSelected ? null : const Color(0xFF404040), 
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null) ...[
              Container(
                width: iconSize + 15,
                height: iconSize + 15,
                // Agregamos un color de fondo temporal para debug
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _isSvg
                    ? SvgPicture.asset(
                        assetPath!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) {
                          return Container(
                            color: const Color.fromARGB(255, 255, 235, 59),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ SVG Error para $label:');
                          debugPrint('   Path: $assetPath');
                          debugPrint('   Error: $error');
                          debugPrint('   Stack: $stackTrace');

                          return Container(
                            width: iconSize,
                            height: iconSize,
                            color: Colors.red.withValues(),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: iconSize * 0.5,
                            ),
                          );
                        },
                        // Agregamos callback para cuando carga exitosamente
                        semanticsLabel: label,
                      )
                    : Image.asset(
                        assetPath!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Image Error: $assetPath - $error');
                          return Container(
                            width: iconSize,
                            height: iconSize,
                            color: Colors.red.withValues(),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: iconSize * 0.5,
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                height: ResponsiveUtils.scaleValue(
                  8.0,
                  scaleFactor,
                  minValue: 6.0,
                  maxValue: 12.0,
                ),
              ),
            ] else ...[
              Container(
                width: iconSize,
                height: iconSize,
                color: Colors.grey.withValues(),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: iconSize * 0.5,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.scaleValue(
                  8.0,
                  scaleFactor,
                  minValue: 6.0,
                  maxValue: 12.0,
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  12.0,
                  scaleFactor,
                ),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
