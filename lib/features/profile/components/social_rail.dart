import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLink {
  final String asset;
  final Uri url;
  final int? followers;
  final int? shares;

  const SocialLink({
    required this.asset,
    required this.url,
    this.followers,
    this.shares,
  });
}

class SocialRail extends StatelessWidget {
  final List<SocialLink> links;
  final double itemSize;
  final double iconSize;
  final bool isDragging;

  const SocialRail({
    super.key,
    required this.links,
    this.itemSize = 50,
    this.iconSize = 45,
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

  @override
  Widget build(BuildContext context) {
    final hasAsset = widget.link.asset.isNotEmpty; // check si tiene ícono

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
      onTap: widget.isDragging ? null : () => _launchUrl(widget.link.url),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasAsset
                    ? (widget.isDragging
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.4))
                    : Colors.purple.shade400,
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: widget.isDragging ? 0.8 : 0.6,
                  ),
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
              child: Center(
                child: hasAsset
                    ? SvgPicture.asset(
                        widget.link.asset,
                        width: widget.iconSize,
                        height: widget.iconSize,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        Icons.link,
                        color: Colors.white,
                        size: widget.iconSize * 0.7,
                      ),
              ),
            ),
            if ((widget.link.followers ?? 0) > 0)
              Positioned(
                top: -4,
                left: -4,
                child: _StatBadge(
                  text: _abbrNumber(widget.link.followers!),
                  color: Colors.blueAccent,
                ),
              ),
            if ((widget.link.shares ?? 0) > 0)
              Positioned(
                bottom: -4,
                right: -4,
                child: _StatBadge(
                  text: _abbrNumber(widget.link.shares!),
                  color: Colors.deepPurpleAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

// Badge pequeño reutilizable
class _StatBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

String _abbrNumber(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0'), '')}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0'), '')}K';
  }
  return n.toString();
}
