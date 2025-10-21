import 'package:flutter/material.dart';

class LoadingOverlay {
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => PopScope(
        canPop: false, // evita cerrar con back button
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    // Verificar si el contexto está montado y si hay un Navigator
    if (!context.mounted) {
      debugPrint('⚠️ [LoadingOverlay] Context no está montado');
      return;
    }

    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      debugPrint('⚠️ [LoadingOverlay] Error al ocultar: $e');
    }
  }
}
