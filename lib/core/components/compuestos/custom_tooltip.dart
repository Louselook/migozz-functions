import 'package:flutter/material.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showAbove;
  final double arrowOffset;

  const CustomTooltip({
    super.key,
    required this.message,
    this.onClose,
    this.showAbove = false,
    this.arrowOffset = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 👉 Ahora todo el tooltip es clickable
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (onClose != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 🔻 Flecha más grande y visible
        Positioned(
          top: showAbove ? null : -10, // si está abajo, flecha arriba
          bottom: showAbove ? -10 : null, // si está arriba, flecha abajo
          left: arrowOffset - 8, // centrar mejor
          child: CustomPaint(
            size: const Size(16, 10), // 👈 más grande
            painter: _TrianglePainter(
              color: Colors.deepPurple,
              invert: !showAbove,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool invert;

  _TrianglePainter({required this.color, this.invert = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    if (invert) {
      // 🔼 Flecha hacia arriba
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      // 🔽 Flecha hacia abajo
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
