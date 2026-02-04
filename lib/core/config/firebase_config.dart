import 'package:firebase_core/firebase_core.dart';
import 'package:migozz_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Verificar si Firebase ya está inicializado
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ✅ Asegurar persistencia de sesión en Web antes de cualquier uso
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          debugPrint(
            '✅ [FirebaseConfig] Persistencia LOCAL configurada para Web',
          );
        } catch (e) {
          debugPrint('❌ [FirebaseConfig] Error configurando persistencia: $e');
        }
      }
    } catch (e) {
      // Si Firebase ya está inicializado, solo ignorar el error
      if (e.toString().contains('duplicate-app')) {
        // Firebase ya está inicializado, continuar
        return;
      }
      // Si es otro error, re-lanzarlo
      rethrow;
    }
  }
}
