import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLink {
  final String asset;
  final Uri url;

  const SocialLink({required this.asset, required this.url});
}

class SocialRail extends StatelessWidget {
  final List<SocialLink> links;
  final double itemSize;
  final double iconSize;
  final bool isDragging;

  const SocialRail({
    super.key,
    required this.links,
    this.itemSize = 40,
    this.iconSize = 40,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isDragging
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDragging ? 0.4 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;

          return Padding(
            padding: EdgeInsets.only(bottom: index < links.length - 1 ? 8 : 0),
            child: _SocialButton(
              link: link,
              size: itemSize,
              iconSize: iconSize,
              isDragging: isDragging,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  final SocialLink link;
  final double size;
  final double iconSize;
  final bool isDragging;

  const _SocialButton({
    required this.link,
    required this.size,
    required this.iconSize,
    this.isDragging = false,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _isPressed = false;

  Widget _buildIcon(String asset, double size) {
    final lower = asset.toLowerCase();
    // Reducir el tamaño del icono para que quepa bien dentro del círculo
    final iconSize = size * 0.6; // 60% del tamaño del contenedor

    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      asset,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDragging
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isDragging
          ? null
          : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.isDragging
          ? null
          : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDragging
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.4),
            border: Border.all(
              color: Colors.white.withValues(alpha: widget.isDragging ? 0.8 : 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // ClipOval para asegurar que nada se salga del círculo
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Padding interno
              child: _buildIcon(widget.link.asset, widget.size),
            ),
          ),
        ),
      ),
    );
  }
}
