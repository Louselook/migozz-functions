import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_validation.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/response_ia_chat.dart';

class ChatController extends ChangeNotifier {
  final RegisterCubit registerCubit;
  ChatController({required this.registerCubit});

  final IaChatService _chatService = IaChatService();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  List<String> _currentSuggestions = [];

  List<Map<String, dynamic>> get messages => _messages;
  List<String> get currentSuggestions => _currentSuggestions;

  bool isExpectingOTP = false;
  TextInputType _keyboardType = TextInputType.text;
  TextInputType get keyboardType => _keyboardType;

  /// ------------------- Inicialización -------------------
  void initializeChat({Function(Map<String, dynamic>)? onActionRequired}) {
    showNextBotMessage(onActionRequired: onActionRequired);
  }

  /// ------------------- Envío de mensajes -------------------
  // import 'chat_validation.dart';

  void handleBotAction(String botResponse) {
    if (botResponse.contains("OTP") || botResponse.contains("código")) {
      isExpectingOTP = true;
    } else {
      isExpectingOTP = false;
    }
    notifyListeners();
  }

  void sendChat({
    required bool other,
    MessageType type = MessageType.text,
    String? text,
    String? audio,
    List<Map<String, String>>? pictures,
    List<String>? options,
    Function(Map<String, dynamic>)? onActionRequired,
  }) {
    if (type == MessageType.text && (text == null || text.trim().isEmpty)) {
      return;
    }

    final message = ChatMessage(
      other: other,
      type: type,
      text: text,
      audio: audio,
      pictures: pictures,
      options: options,
      time: _getTimeNow(),
    );

    _addMessage(message.toMap());

    if (!other) _currentSuggestions = [];

    if (!other) {
      final botIndex = _chatService.currentIndex; // índice actual del bot

      String normalizedResponse;
      if (type == MessageType.text) {
        normalizedResponse = text ?? '';
      } else if (type == MessageType.audio) {
        normalizedResponse = audio ?? "https://storage.fake/voice123.mp3";
      } else if (type == MessageType.pictureCard) {
        normalizedResponse = pictures != null && pictures.isNotEmpty
            ? pictures.first["imageUrl"] ?? "https://picsum.photos/200"
            : "https://picsum.photos/200";
      } else {
        normalizedResponse = '';
      }

      // --------- OTP (índice 9) ---------
      if (botIndex == 9) {
        if (normalizedResponse == registerCubit.state.currentOTP) {
          // OTP correcto
          registerCubit.updateEmailVerification(EmailVerification.success);
          // Avanzar solo si está verificado
          Future.delayed(const Duration(milliseconds: 600), () {
            showNextBotMessage(onActionRequired: onActionRequired);
          });
        } else {
          // OTP incorrecto, repetir la misma pregunta
          _addMessage(
            ChatMessage(
              other: true,
              type: MessageType.text,
              text: "❌ OTP incorrecto. Intenta de nuevo.",
              time: _getTimeNow(),
            ).toMap(),
          );

          // NO avanzamos el botIndex, se queda esperando
          return;
        }
        return; // cortar aquí para no procesar lo de abajo
      }

      // --------- Flujo normal ---------
      // Luego llamas a tu función
      mapResponseToCubit(
        botIndex: botIndex,
        userResponse: normalizedResponse,
        cubit: registerCubit,
      );

      // debugPrint('vamo: ${registerCubit.state}');
      // debugPrint('vamo:  pagina $botIndex');

      if (_messages.length == 2) {
        _chatService.setLanguage(normalizedResponse);
      }

      // 🔹 Mostrar la siguiente respuesta del bot
      Future.delayed(const Duration(milliseconds: 600), () {
        showNextBotMessage(onActionRequired: onActionRequired);
      });
    }
  }

  /// ------------------- Mensajes del bot -------------------
  // En ChatController
  void showNextBotMessage({
    Function(Map<String, dynamic>)? onActionRequired,
    int messagesToShow = 1,
    bool showTyping = true, // 👈 Nuevo parámetro
  }) async {
    if (messagesToShow <= 0) return;

    // Solo mostrar typing si showTyping es true
    if (showTyping) {
      _addMessage({
        "other": true,
        "type": MessageType.typing,
        "name": "Migozz",
        "time": _getTimeNow(),
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
      notifyListeners();
    }

    final botResponse = _chatService.getNextBotResponse(registerCubit);
    if (botResponse == null) return;

    // 👇 Actualiza el keyboardType según la pregunta
    final String? keyboardTypeStr = botResponse["keyboardType"];
    if (keyboardTypeStr == "number") {
      _keyboardType = TextInputType.number;
    } else {
      _keyboardType = TextInputType.text;
    }

    _addMessage({
      "other": true,
      "text": botResponse["text"],
      "options": botResponse["options"] ?? [],
      "type": MessageType.text,
      "time": _getTimeNow(),
    });

    _currentSuggestions = List<String>.from(botResponse["options"] ?? []);

    if (botResponse["action"] != null ||
        botResponse["dinamicResponse"] == "FollowedMessages") {
      onActionRequired?.call(botResponse);
    }

    if (messagesToShow > 1) {
      await Future.delayed(const Duration(milliseconds: 600));
      showNextBotMessage(
        onActionRequired: onActionRequired,
        messagesToShow: messagesToShow - 1,
        showTyping: false, // 👈 No mostrar typing en mensajes consecutivos
      );
    }
    notifyListeners(); // Notifica para que la UI actualice el teclado
  }

  /// Mostrar múltiples mensajes del bot consecutivos con delay
  Future<void> showMultipleBotMessages(int count) async {
    for (int i = 0; i < count; i++) {
      final botResponse = _chatService.getNextBotResponse(registerCubit);
      if (botResponse == null) break;

      _addMessage({
        "other": true,
        "text": botResponse["text"],
        "options": botResponse["options"] ?? [],
        "type": MessageType.text,
        "time": _getTimeNow(),
      });

      _currentSuggestions = List<String>.from(botResponse["options"] ?? []);

      // Solo delay corto entre mensajes, sin typing
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  /// ------------------- Post Action -------------------
  void handlePostActionResponse({
    required Function() onSocialEcosystem,
    required Function() onNormalFlow,
  }) {
    _delayedBotResponseAfterAction(
      onSocialEcosystem: onSocialEcosystem,
      onNormalFlow: onNormalFlow,
    );
  }

  Future<void> _delayedBotResponseAfterAction({
    required Function() onSocialEcosystem,
    required Function() onNormalFlow,
  }) async {
    // Typing
    _addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": _getTimeNow(),
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    notifyListeners();

    // Mensaje real
    final response = _chatService.getNextBotResponse(registerCubit);
    if (response == null) return;

    _addMessage({
      "other": true,
      "text": response["text"],
      "type": MessageType.text,
      "time": _getTimeNow(),
    });

    if (response["dinamicResponse"] == "SocialEcosystemStep") {
      onSocialEcosystem();
    } else {
      onNormalFlow();
    }
  }

  /// ------------------- Tarjetas sociales y de imágenes -------------------
  // Future<void> addSocialCards() async {
  //   final socialCards = [
  //     {
  //       "platform": "Instagram",
  //       "stats": "12.5K followers • 248 posts",
  //       "emoji": "📸",
  //     },
  //     {
  //       "platform": "TikTok",
  //       "stats": "8.2K followers • 156 videos",
  //       "emoji": "📱",
  //     },
  //   ];

  //   for (var card in socialCards) {
  //     await Future.delayed(const Duration(milliseconds: 800));
  //     _addMessage({
  //       "other": true,
  //       "type": MessageType.socialCard,
  //       "social": true,
  //       "platform": card["platform"],
  //       "stats": card["stats"],
  //       "emoji": card["emoji"],
  //       "time": _getTimeNow(),
  //     });
  //   }
  // }

  Future<void> addPictureCards() async {
    final pictureCards = [
      {"imageUrl": "https://picsum.photos/200", "label": "Camera"},
      {"imageUrl": "https://picsum.photos/201", "label": "Gallery"},
      {"imageUrl": "https://picsum.photos/202", "label": "Custom"},
    ];

    await Future.delayed(const Duration(milliseconds: 800));
    _addMessage({
      "other": true,
      "type": MessageType.pictureCard,
      "pictures": pictureCards,
      "time": _getTimeNow(),
    });
  }

  /// ------------------- Utilidades -------------------
  void _addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
    _scrollToBottom();
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

  String _getTimeNow() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
