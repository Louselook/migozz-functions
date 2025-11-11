import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/handle_facebook.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/handle_instagram.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/handle_spotify.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/handle_tiktok.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/handle_twitter.dart';

class DeeplinkService {
  static const _socialChannel = MethodChannel('socialAuth');
  static bool _isInitialized = false;

  /// 🔹 Inicializar el canal UNA SOLA VEZ en toda la app
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    debugPrint('🔗 [DeeplinkService] Inicializando canal de deeplinks');

    _socialChannel.setMethodCallHandler((call) async {
      debugPrint('🔗 [DeeplinkService] Deeplink recibido: ${call.method}');

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

    _isInitialized = true;
  }

  // 🔹 Handlers que actualizan AMBOS cubits según el contexto
  static Future<void> _handleSpotify(String data, BuildContext context) async {
    handleSpotify(data, context);
    await _syncToEditCubit(context, 'spotify');
  }

  static Future<void> _handleTwitter(String data, BuildContext context) async {
    handleTwitter(data, context);
    await _syncToEditCubit(context, 'twitter');
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

  /// 🔹 Sincronizar el último item de RegisterCubit a EditCubit
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

      // Buscar el último item de esta plataforma
      final lastItem = socialEcosystem.lastWhere(
        (item) => item.keys.first.toLowerCase() == platform.toLowerCase(),
        orElse: () => {},
      );

      if (lastItem.isEmpty) {
        debugPrint('⚠️ [DeeplinkService] No se encontró item para $platform');
        return;
      }

      // Actualizar EditCubit
      final currentEdit = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      // Evitar duplicados
      currentEdit.removeWhere(
        (e) => e.keys.first.toLowerCase() == platform.toLowerCase(),
      );

      currentEdit.add(lastItem);
      editCubit.updateSocialEcosystem(currentEdit);

      debugPrint('✅ [DeeplinkService] $platform sincronizado a EditCubit');
      debugPrint(
        '🔹 EditCubit socialEcosystem: ${editCubit.state.socialEcosystem}',
      );

      // 🔹 NUEVA LÓGICA: Verificar si hay un registro REAL activo
      final regProgress = registerCubit.state.regProgress;

      // Un registro está activo si tiene email Y está en progreso (no vacío ni completo)
      final hasEmail =
          registerCubit.state.email != null &&
          registerCubit.state.email!.isNotEmpty;
      final isInProgress =
          regProgress != RegisterStatusProgress.emty &&
          regProgress != RegisterStatusProgress.doneChat;

      final isActiveRegistration = hasEmail && isInProgress;

      debugPrint('🔍 [DeeplinkService] Verificando registro activo:');
      debugPrint('   • hasEmail: $hasEmail');
      debugPrint('   • email: ${registerCubit.state.email}');
      debugPrint('   • regProgress: $regProgress');
      debugPrint('   • isActiveRegistration: $isActiveRegistration');

      if (!isActiveRegistration) {
        // Solo limpiamos si NO hay un registro real activo
        registerCubit.reset();
        debugPrint(
          '🧹 [DeeplinkService] RegisterCubit limpiado (modo edición)',
        );
      } else {
        // Hay un registro real en curso - NO limpiar
        debugPrint(
          '⏸️ [DeeplinkService] RegisterCubit NO limpiado (registro activo)',
        );
      }
    } catch (e, st) {
      debugPrint(
        '❌ [DeeplinkService] Error sincronizando a EditCubit: $e\n$st',
      );
    }
  }
}
