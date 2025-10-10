import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

/// Maneja toda la lógica relacionada con audio en el chat
class AudioChatHandler {
  bool _awaitingAudioConfirmation = false;
  List<String> _currentSuggestions = [];

  bool get isAwaitingConfirmation => _awaitingAudioConfirmation;
  List<String> get currentSuggestions => _currentSuggestions;

  /// Enviar audio del usuario y mostrar confirmación
  Map<String, dynamic> sendUserAudio({
    required String audioPath,
    required RegisterCubit registerCubit,
    required Function(Map<String, dynamic>) addMessage,
    required dynamic chatController,
  }) {
    final isSpanish = (registerCubit.state.language ?? '')
        .toLowerCase()
        .contains('es');

    // 1. Añadir mensaje de audio
    final audioMessage = {
      "other": true,
      "type": MessageType.audioPlayback,
      "audio": audioPath,
      "chatController": chatController,
      "time": getTimeNow(),
    };
    addMessage(audioMessage);

    // 2. Mostrar opciones de confirmación
    final confirmMessage = {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? '¿Deseas conservar ese audio o grabar uno nuevo?'
          : 'Do you want to keep this audio or record a new one?',
      "options": isSpanish
          ? ['Conservar el audio', 'Grabar uno nuevo']
          : ['Keep the audio', 'Record a new one'],
      "time": getTimeNow(),
    };
    addMessage(confirmMessage);

    _currentSuggestions = List<String>.from(confirmMessage["options"] as List);
    _awaitingAudioConfirmation = true;

    return confirmMessage;
  }

  /// Callback cuando termina de reproducirse el audio
  void onAudioFinished({
    required RegisterCubit registerCubit,
    required Function(Map<String, dynamic>) addMessage,
  }) {
    if (_awaitingAudioConfirmation) return; // Ya mostrado

    final isSpanish = (registerCubit.state.language ?? '')
        .toLowerCase()
        .contains('es');

    final confirmMessage = {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? '¿Deseas conservar ese audio o grabar uno nuevo?'
          : 'Do you want to keep this audio or record a new one?',
      "options": isSpanish
          ? ['Conservar el audio', 'Grabar uno nuevo']
          : ['Keep the audio', 'Record a new one'],
      "time": getTimeNow(),
    };

    addMessage(confirmMessage);
    _currentSuggestions = List<String>.from(confirmMessage["options"] as List);
    _awaitingAudioConfirmation = true;
  }

  /// Procesar respuesta del usuario a la confirmación de audio
  /// Retorna:
  /// - 'keep': usuario quiere conservar el audio
  /// - 'record': usuario quiere regrabar
  /// - null: no es una respuesta válida para audio
  String? handleAudioConfirmationResponse(String userText) {
    if (!_awaitingAudioConfirmation || _currentSuggestions.isEmpty) {
      return null;
    }

    final lower = userText.trim().toLowerCase();

    // Verificar si quiere conservar
    final isKeep = [
      'conservar el audio',
      'conservar',
      'keep the audio',
      'keep',
    ].contains(lower);

    // Verificar si quiere regrabar
    final isRecord = [
      'grabar uno nuevo',
      'grabar nuevo',
      'nuevo',
      'record a new one',
      'new one',
      'record new',
    ].contains(lower);

    if (isKeep) {
      _resetState();
      return 'keep';
    }

    if (isRecord) {
      _resetState();
      return 'record';
    }

    return null;
  }

  /// Generar mensaje para regrabar
  Map<String, dynamic> getRecordAgainMessage(RegisterCubit registerCubit) {
    final isSpanish = (registerCubit.state.language ?? '')
        .toLowerCase()
        .contains('es');

    return {
      "other": true,
      "type": MessageType.text,
      "text": isSpanish
          ? '🎤 Graba una nueva nota de voz.'
          : '🎤 Record a new voice note.',
      "time": getTimeNow(),
    };
  }

  /// Resetear estado del handler
  void _resetState() {
    _currentSuggestions = [];
    _awaitingAudioConfirmation = false;
  }

  /// Limpiar completamente el handler
  void reset() {
    _resetState();
  }
}
