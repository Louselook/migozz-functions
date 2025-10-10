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

  Future<void> showNextBotMessage() async {
    registerCubit.setAiResponse(true);

    // Mostrar typing
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

      // Remover typing
      _messages.removeWhere((msg) => msg["type"] == MessageType.typing);

      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": botResponse["text"],
        "options": botResponse["options"] ?? [],
        "step": botResponse["step"],
        "valid": botResponse["valid"],
        "action": botResponse["action"],
        "extracted": botResponse["extracted"],
        "call": botResponse["call"],
        "name": "Migozz",
        "time": getTimeNow(),
      });

      // Ejecutar callback para navegar
      if (onBotAction != null) {
        onBotAction!(botResponse);
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo respuesta IA: $e');
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
      // Añadir mensaje del usuario
      addMessage({
        "other": false,
        "text": text,
        "type": MessageType.text,
        "time": getTimeNow(),
      });

      if (audioResponse == 'keep') {
        // Usuario confirma el audio → continuar con siguiente mensaje
        await Future.delayed(const Duration(milliseconds: 600));
        await showNextBotMessage();
      } else if (audioResponse == 'record') {
        // Usuario quiere regrabar → mostrar mensaje de regrabar
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

    // Limpiar opciones del último mensaje del bot
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
