import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialIconCard extends StatelessWidget {
  final String label;
  final String? assetPath;
  final VoidCallback? onTap;
  final Size? sizeIcon;
  final double iconSize; // Tamaño específico del icono interno

  const SocialIconCard({
    super.key,
    required this.label,
    this.assetPath,
    this.onTap,
    this.sizeIcon,
    this.iconSize = 40.0, // Valor por defecto para el icono
  });

  bool get _isSvg => (assetPath ?? '').toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: sizeIcon?.width ?? 80,
        height: sizeIcon?.height ?? 80,
        decoration: BoxDecoration(
          color: const Color(0xFF404040),
          borderRadius: BorderRadius.circular(15),
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
