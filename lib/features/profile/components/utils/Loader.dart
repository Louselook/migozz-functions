import 'package:flutter/material.dart';
import 'dart:math' as math;

Future<void> showProfileLoader(
  BuildContext context, {
  String message = 'Loading...',
  VoidCallback? onCancel,
  bool barrierDismissible = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Loader',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, a1, a2) => Center(
      child: LoaderDialog(message: message, onCancel: onCancel),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
        child: child,
      ),
    ),
  );
}

class LoaderDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;
  const LoaderDialog({super.key, required this.message, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF7B2CF5), Color(0xFFFF3D6E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'x',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SegmentedSpinner(size: 120, segments: 14),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            _CancelButton(
              onTap: () {
                onCancel?.call();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 42,
        width: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5A6E), Color(0xFFEA1457)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5A6E).withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class SegmentedSpinner extends StatefulWidget {
  final double size;
  final int segments;
  const SegmentedSpinner({super.key, this.size = 100, this.segments = 12});

  @override
  State<SegmentedSpinner> createState() => _SegmentedSpinnerState();
}

class _SegmentedSpinnerState extends State<SegmentedSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _controller.value,
              segments: widget.segments,
              headColor: const Color(0xFFFFFFFF),
              tailColor: const Color(0xFF5B1FB8),
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final int segments;
  final Color headColor;
  final Color tailColor;
  _SpinnerPainter({
    required this.progress,
    required this.segments,
    required this.headColor,
    required this.tailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final stroke = size.width * 0.15;
    final step = 2 * math.pi / segments;
    final rotation = progress * 2 * math.pi;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final headIndex = ((progress * segments)).floor();
    final trailLen = (segments * 0.6).round();

    for (int i = 0; i < segments; i++) {
      final distance = (i - headIndex) % segments;
      final d = distance < 0 ? distance + segments : distance;
      double t = 1.0 - (d / trailLen).clamp(0.0, 1.0);
      t = math.pow(t, 0.6).toDouble();

      final start = -math.pi / 2 + i * step + rotation + step * 0.12 * (1 - t);
      final sweep = step * (0.62 + 0.22 * t);
      basePaint.color = Color.lerp(tailColor, headColor, t)!;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        basePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.segments != segments ||
        oldDelegate.headColor != headColor ||
        oldDelegate.tailColor != tailColor;
  }
}
