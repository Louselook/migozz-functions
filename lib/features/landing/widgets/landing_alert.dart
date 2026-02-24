import 'package:flutter/material.dart';

/// Alert types matching the React Alert component.
enum AlertType { info, success, warning, error }

/// A floating alert notification that auto-closes.
/// Mirrors the React Alert component from LandingMigozz.
class LandingAlert extends StatefulWidget {
  final AlertType type;
  final String message;
  final VoidCallback onClose;
  final Duration autoCloseDuration;

  const LandingAlert({
    super.key,
    this.type = AlertType.info,
    required this.message,
    required this.onClose,
    this.autoCloseDuration = const Duration(seconds: 3),
  });

  @override
  State<LandingAlert> createState() => _LandingAlertState();
}

class _LandingAlertState extends State<LandingAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    if (widget.autoCloseDuration.inMilliseconds > 0) {
      Future.delayed(widget.autoCloseDuration, () {
        if (mounted) widget.onClose();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.type) {
      case AlertType.info:
        return const Color(0xFF3B82F6);
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.error:
        return const Color(0xFFEF4444);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.error:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 500),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: _borderColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: _borderColor, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
