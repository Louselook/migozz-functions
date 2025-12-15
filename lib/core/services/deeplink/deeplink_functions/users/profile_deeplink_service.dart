import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ProfileDeeplinkService {
  static const _channel = MethodChannel('profileDeeplink');
  static bool _isInitialized = false;

  // Guardar la referencia al router
  static GoRouter? _router;

  /// Método para registrar el router (llamar desde main.dart)
  static void setRouter(GoRouter router) {
    _router = router;
    debugPrint('✅ [ProfileDeeplinkService] Router registrado');
  }

  /// Inicializar según la plataforma
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    debugPrint(
      '🔗 [ProfileDeeplinkService] Inicializando para ${kIsWeb ? "WEB" : "MOBILE"}',
    );

    if (!kIsWeb) {
      _initializeMobileChannel();
    } else {
      debugPrint(
        '🌐 [ProfileDeeplinkService] En web - GoRouter maneja las rutas automáticamente',
      );
    }

    _isInitialized = true;
  }

  /// Configurar MethodChannel para mobile
  static void _initializeMobileChannel() {
    _channel.setMethodCallHandler((call) async {
      debugPrint(
        '🔗 [ProfileDeeplinkService] Deep link recibido (mobile): ${call.method}',
      );

      try {
        if (call.method == 'openProfile') {
          final username = call.arguments as String;

          debugPrint(
            '🔍 [ProfileDeeplinkService] Navegando a perfil: $username',
          );

          // Navegar directamente usando el router
          await _navigateToProfile(username);
        }
      } catch (e, st) {
        debugPrint(
          '❌ [ProfileDeeplinkService] Error procesando deep link: $e\n$st',
        );
      }
    });
  }

  /// Navegar al perfil usando la ruta directa
  static Future<void> _navigateToProfile(String username) async {
    // Esperar un momento para asegurar que todo está inicializado
    await Future.delayed(const Duration(milliseconds: 300));

    if (_router == null) {
      debugPrint(
        '⚠️ [ProfileDeeplinkService] Router no disponible, reintentando...',
      );

      // Reintentar después de medio segundo
      await Future.delayed(const Duration(milliseconds: 500));

      if (_router == null) {
        debugPrint('❌ [ProfileDeeplinkService] Router aún no disponible');
        return;
      }
    }

    try {
      final cleanUsername = username.toLowerCase().replaceFirst('@', '');
      final route = '/u/$cleanUsername';

      debugPrint('✅ [ProfileDeeplinkService] Navegando a: $route');

      // Usar go() del router directamente
      _router!.go(route);
    } catch (e, st) {
      debugPrint('❌ [ProfileDeeplinkService] Error en navegación: $e\n$st');
    }
  }

  /// Método público para abrir perfil
  static void openProfileByUsername(String username, BuildContext context) {
    final cleanUsername = username.toLowerCase().replaceFirst('@', '');
    context.go('/u/$cleanUsername');
  }

  /// Limpiar recursos
  static void dispose() {
    _isInitialized = false;
    _router = null;
  }
}
