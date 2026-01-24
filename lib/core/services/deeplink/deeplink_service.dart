import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/users/profile_deeplink_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/handle_facebook.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/handle_instagram.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/handle_spotify.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/handle_tiktok.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/handle_twitter.dart';

class DeeplinkService {
  static const _socialChannel = MethodChannel('socialAuth');
  static bool _isInitialized = false;

  /// Inicializar deeplinks según la plataforma
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    debugPrint(
      '🔗 [DeeplinkService] Inicializando deeplinks para ${kIsWeb ? "WEB" : "MOBILE"}',
    );

    if (kIsWeb) {
      // 🌐 EN WEB: Solo manejar deeplinks de perfiles manualmente si es necesario
      // GoRouter ya maneja automáticamente las rutas como /u/:username
      _initializeWebDeeplinks(context);
    } else {
      // 📱 EN MOBILE: Usar MethodChannel para interceptar intents nativos
      _initializeMobileDeeplinks(context);
    }

    _isInitialized = true;
  }

  /// Inicialización específica para WEB
  static void _initializeWebDeeplinks(BuildContext context) {
    debugPrint(
      '🌐 [DeeplinkService] Web deeplinks listos - GoRouter maneja las rutas automáticamente',
    );

    // En web, GoRouter ya captura las rutas del navegador
    // No necesitas hacer nada más aquí, solo asegúrate de que
    // las rutas estén bien definidas en app_router.dart
  }

  /// Inicialización específica para MOBILE (Android/iOS)
  static void _initializeMobileDeeplinks(BuildContext context) {
    debugPrint('📱 [DeeplinkService] Configurando MethodChannels para mobile');

    // Canal para redes sociales (migozz://...)
    _socialChannel.setMethodCallHandler((call) async {
      debugPrint(
        '🔗 [DeeplinkService] Deeplink social recibido: ${call.method}',
      );

      try {
        switch (call.method) {
          case 'spotifySuccess':
            await _handleSpotify(call.arguments as String, context);
            break;
          case 'twitterSuccess':
            await _handleTwitter(call.arguments as String, context);
            break;
          case 'facebookSuccess':
            await _handleFacebook(call.arguments as String, context);
            break;
          case 'tiktokSuccess':
            await _handleTikTok(call.arguments as String, context);
            break;
          case 'instagramSuccess':
            await _handleInstagram(call.arguments as String, context);
            break;
          default:
            debugPrint(
              '⚠️ [DeeplinkService] Método desconocido: ${call.method}',
            );
        }
      } catch (e, st) {
        debugPrint('❌ [DeeplinkService] Error procesando deeplink: $e\n$st');
      }
    });

    // Inicializar deep links de perfiles para mobile
    ProfileDeeplinkService.initialize(context);
  }

  // Mantén tus handlers existentes
  static Future<void> _handleSpotify(String data, BuildContext context) async {
    handleSpotify(data, context);
    await _syncToEditCubit(context, 'spotify');
  }

  static Future<void> _handleTwitter(String data, BuildContext context) async {
    handleTwitter(data, context);
    await _syncToEditCubit(context, 'x');
  }

  static Future<void> _handleFacebook(String data, BuildContext context) async {
    handleFacebook(data, context);
    await _syncToEditCubit(context, 'facebook');
  }

  static Future<void> _handleTikTok(String data, BuildContext context) async {
    handleTikTok(data, context);
    await _syncToEditCubit(context, 'tiktok');
  }

  static Future<void> _handleInstagram(
    String data,
    BuildContext context,
  ) async {
    handleInstagram(data, context);
    await _syncToEditCubit(context, 'instagram');
  }

  static Future<void> _syncToEditCubit(
    BuildContext context,
    String platform,
  ) async {
    try {
      final registerCubit = context.read<RegisterCubit>();
      final editCubit = context.read<EditCubit>();

      final socialEcosystem = registerCubit.state.socialEcosystem;
      if (socialEcosystem == null || socialEcosystem.isEmpty) {
        debugPrint('⚠️ [DeeplinkService] No hay datos en RegisterCubit');
        return;
      }

      final lastItem = socialEcosystem.lastWhere(
        (item) => item.keys.first.toLowerCase() == platform.toLowerCase(),
        orElse: () => {},
      );

      if (lastItem.isEmpty) {
        debugPrint('⚠️ [DeeplinkService] No se encontró item para $platform');
        return;
      }

      final currentEdit = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      currentEdit.removeWhere(
        (e) => e.keys.first.toLowerCase() == platform.toLowerCase(),
      );

      currentEdit.add(lastItem);
      editCubit.updateSocialEcosystem(currentEdit);

      debugPrint('✅ [DeeplinkService] $platform sincronizado a EditCubit');

      final regProgress = registerCubit.state.regProgress;
      final hasEmail =
          registerCubit.state.email != null &&
          registerCubit.state.email!.isNotEmpty;
      final isInProgress =
          regProgress != RegisterStatusProgress.emty &&
          regProgress != RegisterStatusProgress.doneChat;

      final isActiveRegistration = hasEmail && isInProgress;

      if (!isActiveRegistration) {
        registerCubit.reset();
        debugPrint(
          '🧹 [DeeplinkService] RegisterCubit limpiado (modo edición)',
        );
      }
    } catch (e, st) {
      debugPrint(
        '❌ [DeeplinkService] Error sincronizando a EditCubit: $e\n$st',
      );
    }
  }
}
