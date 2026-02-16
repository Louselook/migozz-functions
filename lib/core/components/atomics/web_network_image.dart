import 'package:flutter/material.dart';

class WebNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingBuilder;
  final double borderRadius;

  const WebNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingBuilder,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return loadingBuilder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Container(color: Colors.black);
        },
      ),
    );
  }
}
