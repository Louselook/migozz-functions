import 'dart:io';

import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/audio_chat_handler.dart';

class ChatControllerTest extends ChangeNotifier {
  final RegisterCubit registerCubit;
  ChatControllerTest({required this.registerCubit});

  /// --- Estado activo/inactivo del chat ---
  bool _active = true;
  bool get isActive => _active;

  /// Handler opcional para acciones que requieren navegación externa
  void Function(Map<String, dynamic> botResponse)? onBotAction;

  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;
  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  // Handler para toda la lógica de audio
  final AudioChatHandler _audioHandler = AudioChatHandler();
  List<String> get currentSuggestions => _audioHandler.currentSuggestions;

  /// Inicializa el chat y lo marca como activo
  void initializeChat({void Function(Map<String, dynamic>)? onActionRequired}) {
    GeminiService.instance.ensureConfigured();
    onBotAction = onActionRequired;
    _active = true;
    showNextBotMessage();
  }

  /// Termina y destruye el chat — llama esto antes de navegar fuera
  Future<void> terminateChat({bool clearMessages = false}) async {
    if (!_active) return;
    _active = false;

    // Resetear audio/recorders/reproducciones
    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler: $e');
    }

    // Limpiar mensajes (opcional)
    if (clearMessages) {
      _messages.clear();
    }

    // Quitar callbacks y liberar recursos
    onBotAction = null;

    // Notificar UI para que actualice (y deje de mostrar controls)
    notifyListeners();
  }

  /// Callback cuando el audio termina de reproducirse
  void onAudioFinished() {
    if (!_active) return;
    _audioHandler.onAudioFinished(
      registerCubit: registerCubit,
      addMessage: addMessage,
    );
    notifyListeners();
  }

  /// Enviar audio del usuario
  Future<void> sendUserAudio(String audioPath) async {
    if (!_active) return;

    // Delegar al handler para procesar el audio
    await _audioHandler.sendUserAudio(
      audioPath: audioPath,
      registerCubit: registerCubit,
      addMessage: addMessage,
      chatController: this,
    );

    if (!_active) return;

    // Establecer lastUserMessage para que el flujo continúe
    _lastUserMessage = audioPath;

    // Avanzar automáticamente al siguiente paso
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_active) return;
    await showNextBotMessage();

    notifyListeners();
  }

  /// Manejar envío de foto de avatar (URL o archivo local)
  Future<void> sendAvatarPhoto(String photoPath) async {
    if (!_active) return;

    debugPrint('📸 Foto de avatar recibida: $photoPath');

    // Agregar mensaje visual del usuario
    addMessage({
      "other": false,
      "type": MessageType.pictureCard,
      "pictures": [
        {"imageUrl": photoPath, "label": "Mi foto de perfil"},
      ],
      "time": getTimeNow(),
    });

    // Determinar si es URL o archivo local
    final isUrl = photoPath.startsWith('http');

    if (isUrl) {
      debugPrint('✅ URL de avatar guardada: $photoPath');
      // Si quieres persistir la URL ya aquí en el cubit:
      registerCubit.setAvatarUrl(photoPath);
    } else {
      // Es un archivo local (galería/cámara)
      final file = File(photoPath);
      if (await file.exists()) {
        registerCubit.setAvatarFile(file);
        debugPrint('✅ Archivo de avatar guardado: $photoPath');
      } else {
        debugPrint('❌ Archivo no encontrado: $photoPath');
        return;
      }
    }

    // Simular respuesta para avanzar en el flujo
    _lastUserMessage = photoPath;

    // Mostrar siguiente mensaje (teléfono u otro)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_active) return;
    await showNextBotMessage();
  }

  /// Obtener próxima respuesta del bot (protegida por _active)
  Future<void> showNextBotMessage() async {
    if (!_active) return;

    registerCubit.setAiResponse(true);

    // Añadir typing solo si sigue activo
    if (_active) {
      addMessage({
        "other": true,
        "type": MessageType.typing,
        "name": "Migozz",
        "time": getTimeNow(),
      });
      notifyListeners();
    }

    try {
      final userInput = _lastUserMessage ?? '';
      final botResponse = await GeminiService.instance.sendMessage(
        userInput,
        registerCubit: registerCubit,
      );

      // Si el chat fue terminado mientras esperábamos, ignorar la respuesta
      if (!_active) return;

      _messages.removeWhere((msg) => msg["type"] == MessageType.typing);

      final message = {
        "other": true,
        "type": MessageType.text,
        "text": botResponse["text"],
        "options": botResponse["options"] ?? [],
        "step": botResponse["step"],
        "valid": botResponse["valid"],
        "action": botResponse["action"],
        "name": "Migozz",
        "time": getTimeNow(),
      };

      if (botResponse["isError"] == true) {
        message["isError"] = true;
      }

      if (botResponse["profilePictures"] != null) {
        message["profilePictures"] = botResponse["profilePictures"];
      }

      addMessage(message);

      if (!_active) return;

      if (botResponse["autoAdvance"] == true) {
        debugPrint(
          '🎉 Mensaje de éxito detectado, avanzando automáticamente...',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!_active) return;
        _lastUserMessage = 'continue';
        await showNextBotMessage();
        return;
      }

      if (onBotAction != null) {
        Future.delayed(const Duration(milliseconds: 850), () {
          if (!_active) return;
          onBotAction!(botResponse);
        });
      }
    } catch (e) {
      debugPrint('❌ Error en showNextBotMessage: $e');
    } finally {
      if (_active) registerCubit.setAiResponse(false);
      notifyListeners();
    }
  }

  /// Enviar mensaje de texto del usuario (protegido por _active)
  Future<void> sendUserMessage(String text) async {
    if (!_active) return;
    if (text.trim().isEmpty) return;

    // Delegar manejo de confirmación de audio al handler
    final audioResponse = _audioHandler.handleAudioConfirmationResponse(text);

    if (audioResponse != null) {
      addMessage({
        "other": false,
        "text": text,
        "type": MessageType.text,
        "time": getTimeNow(),
      });

      if (audioResponse == 'keep') {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!_active) return;
        await showNextBotMessage();
      } else if (audioResponse == 'record') {
        final recordMessage = _audioHandler.getRecordAgainMessage(
          registerCubit,
        );
        addMessage(recordMessage);
        notifyListeners();
      }
      return;
    }

    // Flujo normal de mensajes de texto
    _lastUserMessage = text;

    addMessage({
      "other": false,
      "text": text,
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    await showNextBotMessage();
  }

  void addMessage(Map<String, dynamic> message) {
    if (!_active) return;
    _messages.add(message);
    notifyListeners();
    _scrollToBottom();
  }

  void onSuggestionSelected(String suggestion) {
    if (!_active) return;

    sendUserMessage(suggestion);

    for (var msg in _messages.reversed) {
      if (msg["other"] == true && msg["options"] != null) {
        msg["options"] = [];
        break;
      }
    }

    notifyListeners();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active) return;
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Asegurar que el chat esté marcado como inactivo y limpiar recursos
    _active = false;
    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler en dispose: $e');
    }
    scrollController.dispose();
    super.dispose();
  }
}
