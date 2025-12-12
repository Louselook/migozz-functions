import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class LoadingOverlayWithCancel {
  static OverlayEntry? _overlayEntry;
  static bool _isCancelled = false;

  static void show(
    BuildContext context, {
    String message = 'Loading...',
    VoidCallback? onCancel,
  }) {
    debugPrint('🔄 [LoadingOverlay] Showing overlay: $message');

    // Hide keyboard when showing overlay
    FocusScope.of(context).unfocus();

    // Remove any existing overlay first
    hide();

    _isCancelled = false;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(
        message: message,
        onCancel: () {
          debugPrint('❌ [LoadingOverlay] Cancel button pressed');
          _isCancelled = true;
          hide();
          onCancel?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    debugPrint('✅ [LoadingOverlay] Overlay inserted');
  }

  static void hide() {
    debugPrint('🔄 [LoadingOverlay] Hiding overlay...');
    try {
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      debugPrint('✅ [LoadingOverlay] Overlay removed and disposed');
    } catch (e) {
      debugPrint('⚠️ [LoadingOverlay] Error hiding overlay: $e');
    } finally {
      _overlayEntry = null;
    }
  }

  static bool get isCancelled => _isCancelled;
}

class _LoadingOverlayWidget extends StatefulWidget {
  final String message;
  final VoidCallback onCancel;

  const _LoadingOverlayWidget({
    required this.message,
    required this.onCancel,
  });

  @override
  State<_LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<_LoadingOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: AppColors.verticalPinkPurple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Custom circular progress indicator
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Loading text
              Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'buttons.cancel'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circles (segments)
    final segmentPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    const segmentCount = 12;
    const segmentAngle = (2 * 3.14159) / segmentCount;

    for (int i = 0; i < segmentCount; i++) {
      final angle = i * segmentAngle + (progress * 2 * 3.14159);
      final opacity = (i / segmentCount);

      segmentPaint.color = Colors.white.withValues(alpha: 0.3 + (opacity * 0.7));

      final startAngle = angle;
      final sweepAngle = segmentAngle * 0.6;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, segmentPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

