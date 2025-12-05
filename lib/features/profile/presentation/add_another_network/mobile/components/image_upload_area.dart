import 'dart:io';
import 'package:flutter/material.dart';

class ImageUploadArea extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;
  final double size;
  final String defaultAssetPath;

  const ImageUploadArea({
    super.key,
    required this.onTap,
    this.imageFile,
    this.imageUrl,
    this.size = 160,
    this.defaultAssetPath = 'assets/images/OtherIconDefault.webp',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 10),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.06),
              child: ClipOval(child: _buildPreview()),
            ),
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, size: 64, color: Colors.white),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, size: 64, color: Colors.white),
      );
    }
    return Image.asset(
      defaultAssetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _DefaultGlobe(),
    );
  }
}

class _DefaultGlobe extends StatelessWidget {
  const _DefaultGlobe();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlobePainter(), child: Container());
  }
}

class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    final gradient = const LinearGradient(
      colors: [Color(0xFFFF6E3A), Color(0xFFD43AB6), Color(0xFF9321BD)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).createShader(rect);

    final fill = Paint()..shader = gradient;
    canvas.drawCircle(center, r, fill);

    final line = Paint()
      ..color = const Color(0xFF7A6E80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06;

    canvas.drawCircle(center, r * 0.95, line);

    canvas.drawLine(
      Offset(center.dx, center.dy - r * 0.9),
      Offset(center.dx, center.dy + r * 0.9),
      line,
    );

    final ovalW1 = Rect.fromCenter(
      center: center,
      width: r * 1.3,
      height: r * 1.9,
    );
    final ovalW2 = Rect.fromCenter(
      center: center,
      width: r * 0.7,
      height: r * 1.9,
    );

    canvas.drawOval(ovalW1, line);
    canvas.drawOval(ovalW2, line);

    final lat1 = Rect.fromCenter(
      center: center,
      width: r * 1.9,
      height: r * 1.0,
    );
    final lat2 = Rect.fromCenter(
      center: center,
      width: r * 1.9,
      height: r * 0.45,
    );

    canvas.drawOval(lat1, line);
    canvas.drawOval(lat2, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
