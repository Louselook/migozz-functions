import 'package:flutter/material.dart';

enum SnackbarType { success, warning, error, info }

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 4),
    bool showCloseButton = true,
    VoidCallback? onTap,
  }) {
    final snackbarData = _getSnackbarData(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(snackbarData.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showCloseButton)
              GestureDetector(
                onTap: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
          ],
        ),
        backgroundColor: snackbarData.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        onVisible: onTap,
      ),
    );
  }

  static _SnackbarData _getSnackbarData(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarData(
          backgroundColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        );
      case SnackbarType.warning:
        return _SnackbarData(
          backgroundColor: const Color(0xFFFF9800),
          icon: Icons.warning,
        );
      case SnackbarType.error:
        return _SnackbarData(
          backgroundColor: const Color(0xFFF44336),
          icon: Icons.error,
        );
      case SnackbarType.info:
        return _SnackbarData(
          backgroundColor: const Color(0xFF2196F3),
          icon: Icons.info,
        );
    }
  }
}

class _SnackbarData {
  final Color backgroundColor;
  final IconData icon;

  _SnackbarData({required this.backgroundColor, required this.icon});
}

// Clase alternativa para mostrar como Container (similar a tu código actual)
class CustomSnackbarContainer extends StatelessWidget {
  final String message;
  final SnackbarType type;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const CustomSnackbarContainer({
    super.key,
    required this.message,
    required this.type,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final snackbarData = _getSnackbarData(type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: snackbarData.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: snackbarData.backgroundColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            snackbarData.icon,
            color: snackbarData.backgroundColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: snackbarData.backgroundColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          if (showCloseButton && onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                color: snackbarData.backgroundColor,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  _SnackbarData _getSnackbarData(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarData(
          backgroundColor: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
        );
      case SnackbarType.warning:
        return _SnackbarData(
          backgroundColor: const Color(0xFFFF9800),
          icon: Icons.warning,
        );
      case SnackbarType.error:
        return _SnackbarData(
          backgroundColor: const Color(0xFFF44336),
          icon: Icons.error,
        );
      case SnackbarType.info:
        return _SnackbarData(
          backgroundColor: const Color(0xFF2196F3),
          icon: Icons.info,
        );
    }
  }
}
