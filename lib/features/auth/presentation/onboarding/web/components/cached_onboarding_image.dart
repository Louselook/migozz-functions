import 'package:flutter/material.dart';

/// Widget optimizado para cargar imágenes en onboarding con mejor manejo de errores
/// Especialmente útil para Flutter Web en navegadores como Edge
class CachedOnboardingImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? scale;
  final AlignmentGeometry alignment;

  const CachedOnboardingImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.scale,
    this.alignment = Alignment.center,
  });

  @override
  State<CachedOnboardingImage> createState() => _CachedOnboardingImageState();
}

class _CachedOnboardingImageState extends State<CachedOnboardingImage> {
  ImageProvider? _imageProvider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedOnboardingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  void _loadImage() {
    setState(() {
      _hasError = false;
      _imageProvider = AssetImage(widget.imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.white54,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Image(
        key: ValueKey<String>(widget.imagePath),
        image: _imageProvider!,
        fit: widget.fit,
        alignment: widget.alignment,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          // Muestra un fade-in suave cuando la imagen carga
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
          debugPrint('Error loading image ${widget.imagePath}: $error');
          return Container(
            color: Colors.grey.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.white54,
              ),
            ),
          );
        },
      ),
    );
  }
}
