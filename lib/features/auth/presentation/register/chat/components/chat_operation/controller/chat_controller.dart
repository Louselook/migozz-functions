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

  void Function(Map<String, dynamic> botResponse)? onBotAction;

  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;
  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  // Handler para toda la lógica de audio
  final AudioChatHandler _audioHandler = AudioChatHandler();
  List<String> get currentSuggestions => _audioHandler.currentSuggestions;

  void initializeChat({void Function(Map<String, dynamic>)? onActionRequired}) {
    GeminiService.instance.ensureConfigured();
    onBotAction = onActionRequired;
    showNextBotMessage();
  }

  /// Callback cuando el audio termina de reproducirse
  void onAudioFinished() {
    _audioHandler.onAudioFinished(
      registerCubit: registerCubit,
      addMessage: addMessage,
    );
    notifyListeners();
  }

  /// Enviar audio del usuario
  Future<void> sendUserAudio(String audioPath) async {
    _audioHandler.sendUserAudio(
      audioPath: audioPath,
      registerCubit: registerCubit,
      addMessage: addMessage,
      chatController: this,
    );
    notifyListeners();
  }

  /// ✅ Manejar envío de foto de avatar (URL o archivo local)
  Future<void> sendAvatarPhoto(String photoPath) async {
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
      // Es una foto de red social (URL)
      registerCubit.setAvatarUrl(photoPath);
      debugPrint('✅ URL de avatar guardada: $photoPath');
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

    // Mostrar siguiente mensaje (teléfono)
    await Future.delayed(const Duration(milliseconds: 600));
    await showNextBotMessage();
  }

  Future<void> showNextBotMessage() async {
    registerCubit.setAiResponse(true);

    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });
    notifyListeners();

    try {
      final userInput = _lastUserMessage ?? '';
      final botResponse = await GeminiService.instance.sendMessage(
        userInput,
        registerCubit: registerCubit,
      );

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

      if (botResponse["autoAdvance"] == true) {
        debugPrint(
          '🎉 Mensaje de éxito detectado, avanzando automáticamente...',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        _lastUserMessage = 'continue';
        await showNextBotMessage();
        return;
      }

      if (onBotAction != null) {
        Future.delayed(const Duration(milliseconds: 850), () {
          onBotAction!(botResponse);
        });
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    } finally {
      registerCubit.setAiResponse(false);
      notifyListeners();
    }
  }

  Future<void> sendUserMessage(String text) async {
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
    _messages.add(message);
    notifyListeners();
    _scrollToBottom();
  }

  void onSuggestionSelected(String suggestion) {
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
    _audioHandler.reset();
    scrollController.dispose();
    super.dispose();
  }
}
