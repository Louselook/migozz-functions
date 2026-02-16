import 'package:flutter/material.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_coach.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_service.dart';

/// Helper para gestionar el flujo completo del tutorial del perfil
class ProfileTutorialHelper {
  static const List<String> _navKeyNames = <String>[
    'homeNav',
    'searchNav',
    'messagesNav',
    'statsNav',
    'settingsNav',
  ];

  /// Poll de keys hasta que la UI monte los widgets.
  ///
  /// Evita esperar en secuencia por cada key (lo cual multiplica el tiempo).
  static Future<Map<String, bool>> _pollAvailableKeys(
    ProfileTutorialKeys keys, {
    Duration timeout = const Duration(milliseconds: 4500),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final keyMap = <String, GlobalKey>{
      'homeNav': keys.homeNavKey,
      'searchNav': keys.searchNavKey,
      'messagesNav': keys.messagesNavKey,
      'statsNav': keys.statsNavKey,
      'settingsNav': keys.settingsNavKey,
      'linkedNetworks': keys.linkedNetworksKey,
      'shareQr': keys.shareQrKey,
      'community': keys.communityKey,
      'messagesHeader': keys.messagesHeaderKey,
      'nameSection': keys.nameSectionKey,
      'notifications': keys.notificationsKey,
      'qrScanner': keys.qrScannerKey,
      'editProfile': keys.editProfileKey,
    };

    final result = <String, bool>{
      for (final entry in keyMap.entries) entry.key: false,
    };

    final endAt = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endAt)) {
      for (final entry in keyMap.entries) {
        if (result[entry.key] == true) continue;
        if (entry.value.currentContext != null) {
          result[entry.key] = true;
        }
      }

      if (_hasMinimumTargets(result)) {
        break;
      }

      await Future.delayed(interval);
    }

    debugPrint(
      '📋 Keys disponibles: ${result.entries.where((e) => e.value).map((e) => e.key).join(", ")}',
    );
    return result;
  }

  static bool _hasMinimumTargets(Map<String, bool> availableKeys) {
    final navReady = _navKeyNames.every((name) => availableKeys[name] == true);

    // Targets del perfil que siempre deberían existir en la pantalla principal.
    final coreProfileReady =
        (availableKeys['nameSection'] == true) &&
        (availableKeys['shareQr'] == true) &&
        (availableKeys['editProfile'] == true);

    return navReady && coreProfileReady;
  }

  /// Intenta mostrar el tutorial del perfil
  ///
  /// [context] - BuildContext actual
  /// [keys] - Las keys del tutorial
  /// [forceShow] - Si es true, muestra el tutorial incluso si ya fue completado
  /// [initialDelayMs] - Delay inicial antes de verificar las keys
  static Future<void> triggerProfileTutorial(
    BuildContext context,
    ProfileTutorialKeys keys, {
    bool forceShow = false,
    int initialDelayMs = 300,
    int autoRetries = 1,
  }) async {
    debugPrint(
      '🎓 [ProfileTutorialHelper] Iniciando verificación del tutorial...',
    );

    // Verificar si ya completó el tutorial (a menos que sea forzado)
    if (!forceShow) {
      final alreadyCompleted =
          await ProfileTutorialService.hasCompletedTutorial();
      if (alreadyCompleted) {
        debugPrint(
          '🎓 [ProfileTutorialHelper] Tutorial ya completado; no se mostrará.',
        );
        return;
      }
    }

    // Pequeño delay inicial para que la pantalla se monte completamente
    await Future.delayed(Duration(milliseconds: initialDelayMs));

    // Verificar qué keys están disponibles (poll hasta que la UI monte)
    final availableKeys = await _pollAvailableKeys(keys);

    // Si aún no están los targets mínimos, reintentar una vez.
    if (!_hasMinimumTargets(availableKeys)) {
      debugPrint(
        '⚠️ [ProfileTutorialHelper] La UI aún no está lista para el tutorial.',
      );
      if (autoRetries > 0 && context.mounted) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!context.mounted) return;
          
          triggerProfileTutorial(
            context,
            keys,
            forceShow: forceShow,
            initialDelayMs: 250,
            autoRetries: autoRetries - 1,
          );
        });
        return;
      }
      return;
    }

    // Esperar un frame extra para estabilizar
    await Future.delayed(const Duration(milliseconds: 150));

    // Verificar que el context sigue válido
    if (!context.mounted) {
      debugPrint('⚠️ [ProfileTutorialHelper] Context no está montado');
      return;
    }

    // Mostrar pantalla de bienvenida y luego el tutorial
    _showWelcomeAndTutorial(context, keys, markAsCompleteOnEnd: true);
  }

  /// Muestra la pantalla de bienvenida y luego el tutorial
  static void _showWelcomeAndTutorial(
    BuildContext context,
    ProfileTutorialKeys keys, {
    required bool markAsCompleteOnEnd,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: TutorialWelcomeScreen(
            onStart: () {
              // Cerrar la pantalla de bienvenida
              Navigator.of(dialogContext).pop();

              // Iniciar el tutorial coach
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ProfileTutorialCoach.showTutorial(
                    context,
                    keys,
                    onFinish: markAsCompleteOnEnd
                        ? () async {
                            await ProfileTutorialService.markTutorialAsComplete();
                          }
                        : null,
                    onSkip: markAsCompleteOnEnd
                        ? () async {
                            await ProfileTutorialService.markTutorialAsComplete();
                          }
                        : null,
                  );
                }
              });
            },
            onSkip: () async {
              // Cerrar (y opcionalmente marcar como completado)
              Navigator.of(dialogContext).pop();
              if (markAsCompleteOnEnd) {
                await ProfileTutorialService.markTutorialAsComplete();
              }
            },
          ),
        );
      },
    );
  }

  /// Fuerza la reproducción del tutorial (desde el botón de ayuda)
  /// Esta versión NO modifica Firebase.
  static Future<void> replayTutorial(
    BuildContext context,
    ProfileTutorialKeys keys, {
    int initialDelayMs = 300,
  }) async {
    debugPrint(
      '🔄 [ProfileTutorialHelper] Reproduciendo tutorial por petición del usuario',
    );

    await Future.delayed(Duration(milliseconds: initialDelayMs));
    final availableKeys = await _pollAvailableKeys(keys);
    if (!_hasMinimumTargets(availableKeys)) {
      debugPrint(
        '⚠️ [ProfileTutorialHelper] UI no lista para replay del tutorial.',
      );
      return;
    }

    if (!context.mounted) return;
    _showWelcomeAndTutorial(context, keys, markAsCompleteOnEnd: false);
  }
}
