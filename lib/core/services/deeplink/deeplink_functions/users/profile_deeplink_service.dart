import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

class ProfileDeeplinkService {
  static const _channel = MethodChannel('profileDeeplink');
  static bool _isInitialized = false;

  /// Inicializar el canal de deep links de perfiles
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    debugPrint(
      '🔗 [ProfileDeeplinkService] Inicializando canal de deep links de perfiles',
    );

    _channel.setMethodCallHandler((call) async {
      debugPrint(
        '🔗 [ProfileDeeplinkService] Deep link recibido: ${call.method}',
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

    _isInitialized = true;
  }

  /// Manejar deep link de perfil
  static Future<void> _handleProfileDeeplink(
    String username,
    BuildContext context,
  ) async {
    try {
      debugPrint('🔍 [ProfileDeeplinkService] Buscando perfil: $username');

      // Limpiar username (remover @ si existe)
      final cleanUsername = username.toLowerCase().replaceFirst('@', '');

      // Buscar usuario en Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ [ProfileDeeplinkService] Usuario no encontrado: $cleanUsername',
        );

        // Mostrar mensaje de error
        if (context.mounted) {
          AlertGeneral.show(context, 4, message: 'Usuario no encontrado');
        }
        return;
      }

      // Obtener datos del usuario
      final userData = querySnapshot.docs.first.data();

      // Crear UserDTO usando fromMap (que maneja todos los campos defensivamente)
      final user = UserDTO.fromMap(userData);

      debugPrint(
        '✅ [ProfileDeeplinkService] Usuario encontrado: ${user.username}',
      );

      // Navegar a la pantalla de perfil
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

  /// Método para abrir un perfil manualmente (útil para web)
  static Future<void> openProfileByUsername(
    String username,
    BuildContext context,
  ) async {
    await _handleProfileDeeplink(username, context);
  }
}
