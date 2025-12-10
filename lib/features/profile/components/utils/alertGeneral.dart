import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

class AlertGeneral {
  static Future<void> show(BuildContext context, int type, {String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _AlertCard(type: type, message: message),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final int type;
  final String? message;

  const _AlertCard({required this.type, this.message});

  @override
  Widget build(BuildContext context) {
    final iconData = _iconFor(type);
    final color = _colorFor(type);

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.8).clamp(280.0, 340.0) as double;

    return Align(
      alignment: const Alignment(0, 0.45),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: cardWidth,
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB930B9), Color(0xFFE26087)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: 48, color: Colors.white),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'x',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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

  IconData _iconFor(int t) {
    switch (t) {
      case 1:
        return Icons.check;
      case 2:
        return Icons.info_outline;
      case 3:
        return Icons.warning_amber_rounded;
      case 4:
        return Icons.close;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorFor(int t) {
    switch (t) {
      case 1:
        return const Color(0xFF22C55E);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
