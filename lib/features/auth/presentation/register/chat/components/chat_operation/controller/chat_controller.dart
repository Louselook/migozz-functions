import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/chat_call_handler.dart';

class ChatControllerTest extends ChangeNotifier {
  final RegisterCubit registerCubit;
  ChatControllerTest({required this.registerCubit});

  void Function(Map<String, dynamic> botResponse)? onBotAction;

  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  TextInputType _keyboardType = TextInputType.text;
  TextInputType get keyboardType => _keyboardType;

  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  // 🔹 Nuevo: flag para saber si estamos esperando validación de OTP
  bool _waitingForOtpValidation = false;

  void initializeChat({void Function(Map<String, dynamic>)? onActionRequired}) {
    try {
      GeminiService.instance.ensureConfigured();
      if (GeminiService.instance.isConfigured) {
        GeminiService.instance.resetSession();
      }
    } catch (_) {}

    onBotAction = onActionRequired;
    showNextBotMessage();
  }

  Future<void> showNextBotMessage() async {
    final gemini = GeminiService.instance;

    registerCubit.setAiResponse(true);

    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });

    notifyListeners();

    debugPrint(
      '🤖 [Chat] Solicitando respuesta IA para paso: ${registerCubit.state.regProgress}',
    );

    final botResponse = await gemini.nextBotTurn(
      state: registerCubit.state,
      lastUserMessage: _lastUserMessage,
    );

    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    registerCubit.setAiResponse(false);

    if (botResponse == null) {
      debugPrint('❌ [Chat] La IA no devolvió respuesta.');
      notifyListeners();
      return;
    }

    final keyboardTypeStr = botResponse["keyboardType"] as String?;
    _keyboardType = keyboardTypeStr == "number"
        ? TextInputType.number
        : TextInputType.text;

    final msg = {
      "other": true,
      "text": botResponse["text"],
      "options": botResponse["options"] ?? [],
      "type": MessageType.text,
      "time": getTimeNow(),
      "action": botResponse["action"],
      "call": botResponse["call"], // 🔹 Importante: pasar el call
    };

    addMessage(msg);

    debugPrint(
      '📊 [Chat] Estado actualizado tras respuesta IA: '
      'lang=${registerCubit.state.language}, '
      'name=${registerCubit.state.fullName}, '
      'user=${registerCubit.state.username}, '
      'gender=${registerCubit.state.gender}, '
      'progress=${registerCubit.state.regProgress}',
    );

    notifyListeners();
  }

  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage({
      "other": false,
      "text": text,
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    _lastUserMessage = text;

    // 🔹 Si estamos esperando validación de OTP, llamar directamente al handler
    if (_waitingForOtpValidation) {
      debugPrint('🔐 Validando OTP del usuario...');
      _waitingForOtpValidation = false; // resetear flag

      final callHandler = ChatCallHandler(
        cubit: registerCubit,
        controller: this,
      );
      await callHandler.handle("verifyEmailOtp", {});
      return; // 🔹 Salir aquí, no continuar con IA
    }

    final gemini = GeminiService.instance;

    registerCubit.setAiResponse(true);

    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });
    notifyListeners();

    final response = await gemini.handleUserInput(
      cubit: registerCubit,
      userInput: text,
    );

    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    registerCubit.setAiResponse(false);

    if (response == null) {
      notifyListeners();
      return;
    }

    final botMsg = {
      "other": true,
      "text": response["text"],
      "options": response["options"] ?? [],
      "type": MessageType.text,
      "time": getTimeNow(),
      "action": response["action"],
      "call": response["call"], // 🔹 Pasar el call
    };

    _keyboardType = (response["keyboardType"] == "number")
        ? TextInputType.number
        : TextInputType.text;

    addMessage(botMsg);

    notifyListeners();
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

  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
    _scrollToBottom();

    // 🔹 Detectar si este mensaje está esperando OTP
    if (message["__waitingForOtp"] == true) {
      _waitingForOtpValidation = true;
      debugPrint('🔒 Esperando validación de OTP del usuario');
    }

    // 🔹 Si el bot manda "call", ejecutamos el manejador externo
    final callName = message["call"];
    if (callName is String && callName.trim().isNotEmpty) {
      debugPrint('📞 Ejecutando call: $callName');
      Future.delayed(const Duration(milliseconds: 800), () async {
        final callHandler = ChatCallHandler(
          cubit: registerCubit,
          controller: this,
        );
        await callHandler.handle(callName, message);
      });
    }

    // 🔹 Si hay "action", mantener la navegación que ya tenías
    if (message["action"] is int &&
        onBotAction != null &&
        message["__actionHandled"] != true) {
      message["__actionHandled"] = true;
      final botResponse = {
        "text": message["text"],
        "options": message["options"] ?? [],
        "keyboardType": message["keyboardType"] ?? "text",
        "valid": message["valid"] ?? false,
        "action": message["action"],
      };
      Future.delayed(const Duration(milliseconds: 1500), () {
        onBotAction?.call(botResponse);
      });
    }
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
}
