import 'package:firebase_core/firebase_core.dart';
import 'package:migozz_app/firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Verificar si Firebase ya está inicializado
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
