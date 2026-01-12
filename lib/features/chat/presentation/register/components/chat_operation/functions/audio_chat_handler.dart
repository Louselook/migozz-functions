import 'dart:io';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:path_provider/path_provider.dart';

class AudioChatHandler {
  List<String> currentSuggestions = [];
  final UserMediaService mediaService = UserMediaService();

  // Estado para manejar confirmación de audio
  String? _pendingAudioPath;
  String? _permanentAudioPath; // Copia permanente para reproducción
  bool _isWaitingForConfirmation = false;

  bool get isWaitingForAudioConfirmation => _isWaitingForConfirmation;

  /// Enviar audio del usuario para el paso de voiceNoteUrl
  Future<void> sendUserAudio({
    required String audioPath,
    required RegisterCubit registerCubit,
    required Function(Map<String, dynamic>) addMessage,
    required VoidCallback removeTyping,
    required dynamic chatController,
  }) async {
    debugPrint('🎤 [AudioHandler] Procesando audio: $audioPath');

    // Verificar que el archivo existe
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      debugPrint('❌ [AudioHandler] Archivo no encontrado: $audioPath');
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": registerCubit.state.language == 'Español'
            ? "❌ Error: No se pudo encontrar el archivo de audio. Intenta grabar nuevamente."
            : "❌ Error: Could not find the audio file. Please try recording again.",
        "time": getTimeNow(),
      });
      return;
    }

    // Crear una copia permanente del audio para reproducción y guardado
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${dir.path}/chat_audio_$timestamp.m4a';

      final permanentFile = await audioFile.copy(permanentPath);
      _permanentAudioPath = permanentFile.path;
      _pendingAudioPath = audioPath; // Guardar referencia al original

      debugPrint(
        '📋 [AudioHandler] Copia permanente creada: $_permanentAudioPath',
      );
    } catch (e) {
      debugPrint('❌ [AudioHandler] Error al crear copia: $e');
      debugPrint('📁 Ruta de audio temporal: ${audioFile.path}');
      debugPrint('📏 Tamaño archivo: ${await audioFile.length()} bytes');
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": registerCubit.state.language == 'Español'
            ? "❌ Error: No se pudo procesar el audio. Intenta nuevamente."
            : "❌ Error: Could not process the audio. Please try again.",
        "time": getTimeNow(),
      });
      return;
    }

    // Marcar que estamos esperando confirmación
    _isWaitingForConfirmation = true;

    debugPrint('📝 [AudioHandler] Audio pendiente de confirmación');

    // Agregar mensaje visual del audio en el chat
    addMessage({
      "other": false,
      "type": MessageType.audio,
      "audio": _permanentAudioPath, // Usar la copia permanente
      "chatController": chatController,
      "time": getTimeNow(),
    });

    // Pequeño delay antes del typing
    await Future.delayed(const Duration(milliseconds: 400));

    // Agregar indicador de typing
    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });

    // Simular que "está pensando"
    await Future.delayed(const Duration(milliseconds: 1200));

    // Remover el typing
    removeTyping();

    // Preparar opciones según idioma
    final isSpanish = registerCubit.state.language == 'Español';
    currentSuggestions = isSpanish
        ? ["Sí, conservar", "No, grabar otro"]
        : ["Yes, keep it", "No, record again"];

    // Para evitar inferencias no deseadas (ej: "grabar" => open_recorder),
    // mandamos rawOptions como mapas con action send_text.
    final rawOptions = currentSuggestions
      .map((label) => {"label": label, "action": "send_text"})
      .toList(growable: false);

    // Mostrar mensaje de confirmación
    addMessage({
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? "¿Quieres conservar este audio? 🎤"
          : "Do you want to keep this audio? 🎤",
      // options: labels (para render default si hace falta)
      "options": currentSuggestions,
      // rawOptions: objetos con action explícita (para SuggestionChips)
      "rawOptions": rawOptions,
      "name": "Migozz",
      "time": getTimeNow(),
    });
  }

  /// Callback cuando el audio termina de reproducirse
  void onAudioFinished({
    required RegisterCubit registerCubit,
    required Function(Map<String, dynamic>) addMessage,
  }) {
    debugPrint('🎵 [AudioHandler] Audio terminó de reproducirse');
  }

  /// Manejar respuestas de confirmación de audio
  String? handleAudioConfirmationResponse(String text) {
    if (!_isWaitingForConfirmation) return null;

    final normalized = text.trim().toLowerCase();

    // Usuario quiere conservar el audio
    if (normalized.contains('sí') ||
        normalized.contains('si') ||
        normalized.contains('yes') ||
        normalized.contains('conservar') ||
        normalized.contains('keep')) {
      debugPrint('✅ [AudioHandler] Usuario confirmó conservar el audio');
      _isWaitingForConfirmation = false;
      currentSuggestions = [];
      return 'keep';
    }

    // Usuario quiere grabar otro
    if (normalized.contains('no') ||
        normalized.contains('grabar') ||
        normalized.contains('record') ||
        normalized.contains('otro') ||
        normalized.contains('again')) {
      debugPrint('🔄 [AudioHandler] Usuario solicitó grabar otro audio');

      // Limpiar archivos temporales
      _cleanupTempFiles();

      _pendingAudioPath = null;
      _permanentAudioPath = null;
      _isWaitingForConfirmation = false;
      currentSuggestions = [];
      return 'record';
    }

    return null;
  }

  Future<void> confirmAudio(
    RegisterCubit registerCubit, {
    VoidCallback? onResetAudioUI,
    Function(Map<String, dynamic>)? addMessage,
    String? firebaseUid, // Agregar este parámetro
  }) async {
    if (_permanentAudioPath == null) {
      debugPrint('⚠️ [AudioHandler] No hay audio permanente para confirmar');
      return;
    }

    final audioFile = File(_permanentAudioPath!);

    if (!audioFile.existsSync()) {
      debugPrint('❌ [AudioHandler] Archivo permanente no existe');
      return;
    }

    // Mostrar typing
    if (addMessage != null) {
      addMessage({
        "other": true,
        "type": MessageType.typing,
        "name": "Migozz",
        "time": getTimeNow(),
      });
    }

    debugPrint('📤 [AudioHandler] Subiendo audio...');

    try {
      // Usar método inteligente en lugar de uploadFilesTemporarily
      final urls = await registerCubit.uploadUserMedia(
        files: {MediaType.voice: audioFile},
        firebaseUid: firebaseUid, // Pasar el UID
      );

      final voiceUrl = urls[MediaType.voice];

      if (voiceUrl != null) {
        debugPrint('✅ [AudioHandler] Audio subido: $voiceUrl');
        registerCubit.setVoiceNoteUrl(voiceUrl);
        registerCubit.setVoiceNoteFile(audioFile);

        if (addMessage != null) {
          final isSpanish = registerCubit.state.language == 'Español';
          addMessage({
            "other": true,
            "type": MessageType.text,
            "text": isSpanish ? "✅ Audio guardado" : "✅ Audio saved",
            "name": "Migozz",
            "time": getTimeNow(),
          });
        }
      } else {
        debugPrint('❌ No se obtuvo URL del audio');
        if (addMessage != null) {
          final isSpanish = registerCubit.state.language == 'Español';
          addMessage({
            "other": true,
            "type": MessageType.text,
            "text": isSpanish ? "❌ Error al guardar" : "❌ Error saving",
            "name": "Migozz",
            "time": getTimeNow(),
            "isError": true,
          });
        }
        registerCubit.setVoiceNoteFile(audioFile);
      }
    } catch (e) {
      debugPrint('❌ Error subiendo audio: $e');
      if (addMessage != null) {
        final isSpanish = registerCubit.state.language == 'Español';
        addMessage({
          "other": true,
          "type": MessageType.text,
          "text": isSpanish ? "❌ Error de conexión" : "❌ Connection error",
          "name": "Migozz",
          "time": getTimeNow(),
          "isError": true,
        });
      }
      registerCubit.setVoiceNoteFile(audioFile);
    }

    await _cleanupOriginalFile();
    onResetAudioUI?.call();
    _pendingAudioPath = null;
    _isWaitingForConfirmation = false;
  }

  /// Limpiar solo el archivo temporal original
  Future<void> _cleanupOriginalFile() async {
    try {
      if (_pendingAudioPath != null) {
        final file = File(_pendingAudioPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
            '🗑️ [AudioHandler] Archivo temporal original eliminado: $_pendingAudioPath',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AudioHandler] Error al limpiar archivo original: $e');
    }
  }

  /// Limpiar todos los archivos temporales
  Future<void> _cleanupTempFiles() async {
    try {
      if (_pendingAudioPath != null) {
        final file = File(_pendingAudioPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
            '🗑️ [AudioHandler] Archivo temporal eliminado: $_pendingAudioPath',
          );
        }
      }

      if (_permanentAudioPath != null) {
        final file = File(_permanentAudioPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
            '🗑️ [AudioHandler] Copia permanente eliminada: $_permanentAudioPath',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AudioHandler] Error al limpiar archivos: $e');
    }
  }

  /// Obtener mensaje para grabar de nuevo
  Map<String, dynamic> getRecordAgainMessage(RegisterCubit registerCubit) {
    final isSpanish = registerCubit.state.language == 'Español';
    final rawOptions = [
      {
        "label": isSpanish ? "Saltar" : "Skip",
        "action": "skip",
      },
    ];
    return {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? "Entiendo. Por favor graba un nuevo audio, o también puedes saltar este paso."
          : "Got it. Please record a new audio, or you can also skip this step.",
      // Mantener sugerencia de skip sin iniciar grabación automática.
      // En español mostramos "Saltar" (se normaliza a Skip en UI), en inglés "Skip".
      "options": [isSpanish ? "Saltar" : "Skip"],
      "rawOptions": rawOptions,
      "time": getTimeNow(),
    };
  }

  /// Resetear estado del handler
  Future<void> reset() async {
    currentSuggestions = [];

    // Limpiar archivos antes de resetear
    await _cleanupTempFiles();

    _pendingAudioPath = null;
    _permanentAudioPath = null;
    _isWaitingForConfirmation = false;

    debugPrint('🔄 [AudioHandler] Reset completo');
  }
}
