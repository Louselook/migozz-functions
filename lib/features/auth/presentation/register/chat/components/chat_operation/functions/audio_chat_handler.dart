import 'dart:io';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:path_provider/path_provider.dart';

class AudioChatHandler {
  List<String> currentSuggestions = [];

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

    // 1️⃣ Verificar que el archivo existe
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

    // 2️⃣ ✅ Crear una copia permanente del audio para reproducción y guardado
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

    // 3️⃣ Marcar que estamos esperando confirmación
    _isWaitingForConfirmation = true;

    debugPrint('📝 [AudioHandler] Audio pendiente de confirmación');

    // 4️⃣ Agregar mensaje visual del audio en el chat
    addMessage({
      "other": false,
      "type": MessageType.audioPlayback,
      "audio": _permanentAudioPath, // Usar la copia permanente
      "chatController": chatController,
      "time": getTimeNow(),
    });

    // 5️⃣ Pequeño delay antes del typing
    await Future.delayed(const Duration(milliseconds: 400));

    // 6️⃣ Agregar indicador de typing
    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });

    // 7️⃣ Simular que "está pensando"
    await Future.delayed(const Duration(milliseconds: 1200));

    // 8️⃣ Remover el typing
    removeTyping();

    // 9️⃣ Preparar opciones según idioma
    final isSpanish = registerCubit.state.language == 'Español';
    currentSuggestions = isSpanish
        ? ["Sí, conservar", "No, grabar otro"]
        : ["Yes, keep it", "No, record again"];

    // 🔟 Mostrar mensaje de confirmación
    addMessage({
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? "¿Quieres conservar este audio? 🎤"
          : "Do you want to keep this audio? 🎤",
      "options": currentSuggestions,
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

  /// ✅ CORRECCIÓN: Confirmar y guardar el audio usando la copia permanente
  void confirmAudio(RegisterCubit registerCubit) {
    if (_permanentAudioPath == null) {
      debugPrint('⚠️ [AudioHandler] No hay audio permanente para confirmar');
      return;
    }

    // ✅ Usar la copia permanente, no el archivo temporal original
    final audioFile = File(_permanentAudioPath!);

    if (!audioFile.existsSync()) {
      debugPrint(
        '❌ [AudioHandler] Archivo permanente no existe: $_permanentAudioPath',
      );
      return;
    }

    registerCubit.setVoiceNoteFile(audioFile);

    debugPrint(
      '✅ [AudioHandler] Audio confirmado y guardado: $_permanentAudioPath',
    );
    debugPrint('✅ [AudioHandler] Tamaño: ${audioFile.lengthSync()} bytes');

    // Limpiar solo el archivo temporal original (no la copia permanente)
    _cleanupOriginalFile();

    _pendingAudioPath = null;
    _isWaitingForConfirmation = false;
  }

  /// ✅ Limpiar solo el archivo temporal original
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
    return {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? "De acuerdo, por favor graba tu nota de voz nuevamente. 🎤"
          : "Alright, please record your voice note again. 🎤",
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
