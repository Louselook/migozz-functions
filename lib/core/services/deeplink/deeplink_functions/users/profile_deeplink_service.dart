import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

class ProfileDeeplinkService {
  static const _channel = MethodChannel('profileDeeplink');
  static bool _isInitialized = false;

  /// Inicializar según la plataforma
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    debugPrint(
      '🔗 [ProfileDeeplinkService] Inicializando para ${kIsWeb ? "WEB" : "MOBILE"}',
    );

    if (!kIsWeb) {
      // Solo en mobile (Android/iOS) configurar el MethodChannel
      _initializeMobileChannel(context);
    } else {
      // En web, GoRouter maneja automáticamente /u/:username
      debugPrint(
        '🌐 [ProfileDeeplinkService] En web - GoRouter maneja las rutas automáticamente',
      );
    }

    _isInitialized = true;
  }

  /// Configurar MethodChannel para mobile
  static void _initializeMobileChannel(BuildContext context) {
    _channel.setMethodCallHandler((call) async {
      debugPrint(
        '🔗 [ProfileDeeplinkService] Deep link recibido (mobile): ${call.method}',
      );

      try {
        if (call.method == 'openProfile') {
          final username = call.arguments as String;
          await _handleProfileDeeplink(username, context);
        }
      } catch (e, st) {
        debugPrint(
          '❌ [ProfileDeeplinkService] Error procesando deep link: $e\n$st',
        );
      }
    });
  }

  /// Manejar deep link de perfil (funciona en todas las plataformas)
  static Future<void> _handleProfileDeeplink(
    String username,
    BuildContext context,
  ) async {
    try {
      debugPrint('🔍 [ProfileDeeplinkService] Buscando perfil: $username');

      final cleanUsername = username.toLowerCase().replaceFirst('@', '');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ [ProfileDeeplinkService] Usuario no encontrado: $cleanUsername',
        );

        if (context.mounted) {
          AlertGeneral.show(context, 4, message: 'Usuario no encontrado');
        }
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final user = UserDTO.fromMap(userData);

      debugPrint(
        '✅ [ProfileDeeplinkService] Usuario encontrado: ${user.username}',
      );

      if (context.mounted) {
        context.push('/profile-view', extra: user);
      }
    } catch (e, st) {
      debugPrint(
        '❌ [ProfileDeeplinkService] Error manejando deep link: $e\n$st',
      );

      if (context.mounted) {
        AlertGeneral.show(context, 4, message: 'Error al cargar el perfil');
      }
    }
  }

  /// Método público para abrir perfil (útil para web y mobile)
  static Future<void> openProfileByUsername(
    String username,
    BuildContext context,
  ) async {
    await _handleProfileDeeplink(username, context);
  }
}
