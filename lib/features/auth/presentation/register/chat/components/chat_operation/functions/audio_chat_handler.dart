import 'dart:io';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class AudioChatHandler {
  List<String> currentSuggestions = [];

  /// Enviar audio del usuario para el paso de voiceNoteUrl
  Future<void> sendUserAudio({
    required String audioPath,
    required RegisterCubit registerCubit,
    required Function(Map<String, dynamic>) addMessage,
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
        "text":
            "❌ Error: No se pudo encontrar el archivo de audio. Intenta grabar nuevamente.",
        "time": getTimeNow(),
      });
      return;
    }

    // 2️⃣ Guardar el archivo en el cubit
    registerCubit.setVoiceNoteFile(audioFile);
    debugPrint('✅ [AudioHandler] Archivo guardado en cubit: $audioPath');
    debugPrint('✅ [AudioHandler] Archivo existe: ${await audioFile.exists()}');
    debugPrint(
      '✅ [AudioHandler] Tamaño del archivo: ${await audioFile.length()} bytes',
    );

    // 3️⃣ Agregar mensaje visual del audio en el chat
    addMessage({
      "other": false,
      "type": MessageType.audioPlayback,
      "audio": audioPath,
      "chatController": chatController,
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

  /// Manejar respuestas de confirmación de audio (si las hay)
  String? handleAudioConfirmationResponse(String text) {
    // Por ahora no necesitamos confirmación
    return null;
  }

  /// Obtener mensaje para grabar de nuevo
  Map<String, dynamic> getRecordAgainMessage(RegisterCubit registerCubit) {
    final isSpanish = registerCubit.state.language == 'Español';
    return {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? "Por favor, graba tu nota de voz nuevamente. 🎤"
          : "Please record your voice note again. 🎤",
      "time": getTimeNow(),
    };
  }

  /// Resetear estado del handler
  void reset() {
    currentSuggestions = [];
    debugPrint('🔄 [AudioHandler] Reset completo');
  }
}
