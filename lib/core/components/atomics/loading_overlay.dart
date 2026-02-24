import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';

class LoadingOverlay {
  static void show(
    BuildContext context, {
    String? message,
    LoaderType type = LoaderType.generic,
    int? delayPerMessageMs, // Custom delay per message in milliseconds
  }) {
    showProfileLoader(
      context,
      message: message,
      type: type,
      barrierDismissible: false,
      delayPerMessageMs: delayPerMessageMs,
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
