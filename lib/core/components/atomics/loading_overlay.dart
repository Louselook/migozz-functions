import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';

class LoadingOverlay {
  static void show(
    BuildContext context, {
    String? message,
    LoaderType type = LoaderType.generic,
  }) {
    showProfileLoader(
      context,
      message: message,
      type: type,
      barrierDismissible: false,
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
