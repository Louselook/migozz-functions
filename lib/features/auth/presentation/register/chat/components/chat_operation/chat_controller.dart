import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_validation.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/social_cards/helper_cards.dart';
import 'package:migozz_app/core/services/bot/response_ia_chat.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

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
  String? _lastUserMessage; // para dar contexto a Gemini
  bool _waitingForNewEmail = false;
  bool _isDisposed = false;
  bool _awaitingInstagramAvatarConfirm =
      false; // Espera confirmación de avatar IG
  bool _awaitingContinueAfterAudio =
      false; // Espera confirmación para continuar después de escuchar

  /// ------------------- Manejo de Audio -------------------
  void onAudioFinished() {
    if (_awaitingContinueAfterAudio) {
      final isSpanish = (registerCubit.state.language ?? '')
          .toLowerCase()
          .contains('es');

      // Mensaje preguntando si desea continuar
      final continueMessage = ChatMessage(
        other: true,
        type: MessageType.text,
        text: isSpanish ? "¿Desea continuar?" : "Do you want to continue?",
        options: isSpanish ? ["Sí", "No"] : ["Yes", "No"],
        time: _getTimeNow(),
      );

      _addMessage(continueMessage.toMap());
      _currentSuggestions = continueMessage.options ?? [];
      _awaitingContinueAfterAudio = false;
      notifyListeners();
    }
  }

  void _handleAudioSentDirectly(String audioPath) {
    final audioMessage = ChatMessage(
      other: true,
      type: MessageType.audioPlayback,
      audio: audioPath,
      time: _getTimeNow(),
    ).toMap();

    // Pasar referencia del controller
    audioMessage["chatController"] = this;
    _addMessage(audioMessage);

    // Cambiar estado para esperar que termine el audio
    _awaitingContinueAfterAudio = true;
    notifyListeners();
  }

  /// ------------------- Inicialización -------------------
  void initializeChat({Function(Map<String, dynamic>)? onActionRequired}) {
    // Reiniciar memoria de IA por cada registro nuevo
    try {
      GeminiService.instance.ensureConfigured();
      if (GeminiService.instance.isConfigured) {
        GeminiService.instance.resetSession();
      }
    } catch (_) {}
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

  Future<void> sendChat({
    required bool other,
    MessageType type = MessageType.text,
    String? text,
    String? audio,
    List<Map<String, String>>? pictures,
    List<String>? options,
    Function(Map<String, dynamic>)? onActionRequired,
  }) async {
    if (type == MessageType.text && (text == null || text.trim().isEmpty)) {
      return;
    }

    // Solo añadir el mensaje si NO es un audio del usuario
    if (!(type == MessageType.audio && !other)) {
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
    }

    if (!other) _currentSuggestions = [];

    if (!other) {
      final botIndex = _chatService.currentIndex; // índice actual del bot

      String normalizedResponse;
      if (type == MessageType.text) {
        normalizedResponse = text ?? '';
      } else if (type == MessageType.audio) {
        normalizedResponse = audio ?? "https://storage.fake/voice123.mp3";
        _handleAudioSentDirectly(audio ?? "");
        return; // No continuar con el flujo normal
      } else if (type == MessageType.pictureCard) {
        normalizedResponse = pictures != null && pictures.isNotEmpty
            ? pictures.first["imageUrl"] ?? "https://picsum.photos/200"
            : "https://picsum.photos/200";
      } else {
        normalizedResponse = '';
      }

      _lastUserMessage = normalizedResponse;

      // Si el usuario responde a la pregunta de continuar después del audio
      if (_currentSuggestions.isNotEmpty &&
          (_currentSuggestions.contains("Sí") ||
              _currentSuggestions.contains("Yes"))) {
        final lower = normalizedResponse.trim().toLowerCase();
        final isYes = lower == 'sí' || lower == 'si' || lower == 'yes';
        final isNo = lower == 'no';

        if (isYes || isNo) {
          _currentSuggestions = const [];
          notifyListeners();

          // Continuar con el flujo normal independientemente de la respuesta
          Future.delayed(const Duration(milliseconds: 600), () {
            showNextBotMessage(onActionRequired: onActionRequired);
          });
          return;
        }
      }

      // Si estamos esperando confirmación del avatar de Instagram, interceptar respuesta Sí/No
      if (_awaitingInstagramAvatarConfirm) {
        final isSpanish = (registerCubit.state.language ?? '')
            .toLowerCase()
            .contains('es');
        final lower = normalizedResponse.trim().toLowerCase();

        // Normalizar entradas comunes
        final isYes = lower == 'sí' || lower == 'si' || lower == 'yes';
        final isNo = lower == 'no';

        if (isYes || isNo) {
          if (isNo) {
            // El usuario no desea usar la foto de IG como avatar
            registerCubit.clearAvatarUrl();
            _addMessage(
              ChatMessage(
                other: true,
                type: MessageType.text,
                text: isSpanish
                    ? 'Sin problema. No usaré tu foto de Instagram como avatar.'
                    : "No problem. I won't use your Instagram photo as your avatar.",
                time: _getTimeNow(),
              ).toMap(),
            );
          } else {
            // Mantener avatar actual (ya establecido desde IG)
            _addMessage(
              ChatMessage(
                other: true,
                type: MessageType.text,
                text: isSpanish
                    ? 'Perfecto, usaré tu foto de Instagram como avatar.'
                    : 'Great, I will use your Instagram photo as your avatar.',
                time: _getTimeNow(),
              ).toMap(),
            );
          }

          _awaitingInstagramAvatarConfirm = false;
          _currentSuggestions = const [];
          notifyListeners();
          return; // No avanzar índice ni mapear a cubit
        }
        // Si la respuesta no es Sí/No, continúa flujo normal (podría ser otra entrada)
      }

      // Si el usuario hace una pregunta aclaratoria, no mapeamos a cubit
      if (_isClarifyingQuestion(normalizedResponse)) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _showBotMessageInternal(
            onActionRequired: onActionRequired,
            advanceIndex: false,
          );
        });
        return;
      }

      // --------- OTP (índice 9) ---------
      if (botIndex == 9) {
        final isSpanish = (registerCubit.state.language ?? '')
            .toLowerCase()
            .contains('es');

        // Handle special options on OTP step
        final lower = normalizedResponse.trim().toLowerCase();
        final isResend =
            lower == 'resend code' ||
            lower == 'reenviar código' ||
            lower == 'reenviar codigo';
        final isChangeEmail =
            lower == 'change email' ||
            lower == 'cambiar correo' ||
            lower == 'cambiar email';

        // If we're waiting for a new email, treat the input as email
        if (_waitingForNewEmail) {
          // Basic email validation
          final emailOk = RegExp(
            r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}",
          ).hasMatch(normalizedResponse);
          if (!emailOk) {
            _addMessage(
              ChatMessage(
                other: true,
                type: MessageType.text,
                text: isSpanish
                    ? "Formato de correo inválido. Intenta de nuevo."
                    : "Invalid email format. Please try again.",
                time: _getTimeNow(),
              ).toMap(),
            );
            return;
          }

          // Save new email and resend OTP
          registerCubit.setEmail(normalizedResponse);
          try {
            final result = await sendOTP(email: registerCubit.state.email!);
            if (result["sent"] == true) {
              registerCubit.setCurrentOTP(result["myOTP"]);
              _addMessage(
                ChatMessage(
                  other: true,
                  type: MessageType.text,
                  text: isSpanish
                      ? "✅ Te envié un nuevo código OTP a tu nuevo correo. Ingrésalo aquí."
                      : "✅ I sent a new OTP code to your new email. Enter it here.",
                  time: _getTimeNow(),
                ).toMap(),
              );
            } else {
              _addMessage(
                ChatMessage(
                  other: true,
                  type: MessageType.text,
                  text: isSpanish
                      ? "❌ No se pudo enviar el OTP. Intenta más tarde."
                      : "❌ Failed to send OTP. Please try again later.",
                  time: _getTimeNow(),
                ).toMap(),
              );
            }
          } catch (_) {
            _addMessage(
              ChatMessage(
                other: true,
                type: MessageType.text,
                text: isSpanish
                    ? "❌ Ocurrió un error al enviar el OTP."
                    : "❌ An error occurred while sending the OTP.",
                time: _getTimeNow(),
              ).toMap(),
            );
          }

          _waitingForNewEmail = false;
          _currentSuggestions = isSpanish
              ? ["Reenviar código", "Cambiar correo"]
              : ["Resend code", "Change email"];
          notifyListeners();
          return;
        }

        if (isResend) {
          try {
            final result = await sendOTP(email: registerCubit.state.email!);
            if (result["sent"] == true) {
              registerCubit.setCurrentOTP(result["myOTP"]);
              _addMessage(
                ChatMessage(
                  other: true,
                  type: MessageType.text,
                  text: isSpanish
                      ? "✅ Te reenvié el código. Revisa tu correo e ingrésalo aquí."
                      : "✅ I resent the code. Check your email and enter it here.",
                  time: _getTimeNow(),
                ).toMap(),
              );
            } else {
              _addMessage(
                ChatMessage(
                  other: true,
                  type: MessageType.text,
                  text: isSpanish
                      ? "❌ No se pudo reenviar el código."
                      : "❌ Could not resend the code.",
                  time: _getTimeNow(),
                ).toMap(),
              );
            }
          } catch (_) {
            _addMessage(
              ChatMessage(
                other: true,
                type: MessageType.text,
                text: isSpanish
                    ? "❌ Ocurrió un error al reenviar el código."
                    : "❌ An error occurred while resending the code.",
                time: _getTimeNow(),
              ).toMap(),
            );
          }
          _currentSuggestions = isSpanish
              ? ["Reenviar código", "Cambiar correo"]
              : ["Resend code", "Change email"];
          notifyListeners();
          return;
        }

        if (isChangeEmail) {
          _waitingForNewEmail = true;
          _addMessage(
            ChatMessage(
              other: true,
              type: MessageType.text,
              text: isSpanish
                  ? "Perfecto, escribe el nuevo correo electrónico."
                  : "Great, please type the new email address.",
              time: _getTimeNow(),
            ).toMap(),
          );
          _currentSuggestions = const [];
          notifyListeners();
          return;
        }

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
              text: isSpanish
                  ? "❌ OTP incorrecto. Intenta de nuevo."
                  : "❌ Incorrect OTP. Try again.",
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
      debugPrint('respuesta nuemro $botIndex,');
      mapResponseToCubit(
        botIndex: botIndex,
        userResponse: normalizedResponse,
        cubit: registerCubit,
      );

      debugPrint('vamo: ${registerCubit.state}');
      // debugPrint('vamo:  pagina $botIndex');

      // Asegurar idioma del script según el estado del cubit
      if (registerCubit.state.language != null &&
          registerCubit.state.language!.isNotEmpty) {
        _chatService.setLanguage(registerCubit.state.language!);
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

    Map<String, dynamic>? botResponse = await _maybeGeminiOrScripted(
      advanceIndex: true,
    );
    if (botResponse == null) return;

    // Defensive: if text contains a JSON object (possibly code-fenced), parse it
    final t = (botResponse["text"] ?? '').toString();
    if ((botResponse["action"] == null) && t.contains('{') && t.contains('}')) {
      final cleaned = t
          .replaceAll(RegExp(r"```[a-zA-Z]*"), '')
          .replaceAll('```', '')
          .trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonLike = cleaned.substring(start, end + 1);
        try {
          final parsed = jsonDecode(jsonLike);
          if (parsed is Map<String, dynamic>) {
            botResponse = parsed;
          }
        } catch (_) {}
      }
    }

    // 👇 Actualiza el keyboardType según la pregunta
    final Map<String, dynamic> br = Map<String, dynamic>.from(
      botResponse as Map<String, dynamic>,
    );
    final String? keyboardTypeStr = br["keyboardType"] as String?;
    if (keyboardTypeStr == "number") {
      _keyboardType = TextInputType.number;
    } else {
      _keyboardType = TextInputType.text;
    }

    _addMessage({
      "other": true,
      "text": br["text"],
      "options": (br["options"] as List?) ?? [],
      "type": MessageType.text,
      "time": _getTimeNow(),
    });

    _currentSuggestions = List<String>.from((br["options"] as List?) ?? []);

    if (br["action"] != null || br["dinamicResponse"] == "FollowedMessages") {
      onActionRequired?.call(br);
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

  // Cuando es aclaración, explicamos y re-preguntamos sin avanzar el índice
  Future<void> _showBotMessageInternal({
    Function(Map<String, dynamic>)? onActionRequired,
    bool advanceIndex = true,
  }) async {
    // Typing opcional
    _addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": _getTimeNow(),
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    notifyListeners();

    final resp = await _maybeGeminiOrScripted(advanceIndex: advanceIndex);
    // clarification state handled inline; no persistent flag needed
    if (resp == null) return;

    _addMessage({
      "other": true,
      "text": resp["text"],
      "options": resp["options"] ?? [],
      "type": MessageType.text,
      "time": _getTimeNow(),
    });

    _currentSuggestions = List<String>.from(resp["options"] ?? []);
    if (resp["action"] != null ||
        resp["dinamicResponse"] == "FollowedMessages") {
      onActionRequired?.call(resp);
    }

    notifyListeners();
  }

  /// Try Gemini first; if null, use scripted service.
  Future<Map<String, dynamic>?> _maybeGeminiOrScripted({
    bool advanceIndex = true,
  }) async {
    try {
      // Usar Gemini solo a partir del paso 11 para evitar fugas tempranas (avatar, etc.)
      final oneBased = _chatService.currentIndex + 1;
      if (oneBased >= 11) {
        final gemini = GeminiService.instance;
        gemini.ensureConfigured();
        if (gemini.isConfigured) {
          final r = await gemini.nextBotTurn(
            state: registerCubit.state,
            stepIndex: oneBased,
            lastUserMessage: _lastUserMessage,
          );
          if (r != null) {
            if (advanceIndex) {
              _chatService.currentIndex++;
            }
            return r;
          }
        }
      }
    } catch (_) {}

    // Fallback guion
    if (advanceIndex) {
      return _chatService.getNextBotResponse(registerCubit);
    } else {
      return _chatService.peekCurrentBotResponse(registerCubit);
    }
  }

  bool _isClarifyingQuestion(String text) {
    final t = text.trim().toLowerCase();
    const patterns = [
      'para que',
      'para qué',
      'que es',
      'qué es',
      'para que sirve',
      'para qué sirve',
      'por que',
      'por qué',
      'ayuda',
      'help',
      'what is',
      'why',
      'how does',
      'explain',
      'explanation',
      '?',
    ];
    return patterns.any((p) => t.contains(p));
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

  Future<void> addPictureCards() async {
    final platforms = registerCubit.state.socialEcosystem ?? [];
    if (platforms.isEmpty) return;

    final pictureCards = <Map<String, String>>[];

    for (final platform in platforms) {
      final key = platform.keys.first; // ej: "youtube", "instagram"
      final data = platform[key] as Map<String, dynamic>;

      // Buscar dinámicamente un campo de imagen
      final possibleKeys = ["profile_image_url"];
      String? imageUrl;

      for (final imgKey in possibleKeys) {
        if (data[imgKey] != null && (data[imgKey] as String).isNotEmpty) {
          imageUrl = data[imgKey] as String;
          break; // usamos el primero que encontremos
        }
      }

      // Si encontramos imagen, añadimos
      if (imageUrl != null) {
        // Usamos cualquier campo de texto amigable como label
        final label =
            data["title"] ??
            data["username"] ??
            data["full_name"] ??
            key; // fallback al nombre de la red social

        pictureCards.add({"imageUrl": imageUrl, "label": label});
      }
    }

    if (pictureCards.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 800));
    _addMessage({
      "other": true,
      "type": MessageType.pictureCard,
      "pictures": pictureCards,
      "time": _getTimeNow(),
    });
  }

  /// ------------------- Social Cards (después de conectar redes) -------------------
  /// ------------------- Social Cards (después de conectar redes) -------------------
  Future<void> addSocialCards() async {
    final platforms = registerCubit.state.socialEcosystem ?? [];
    if (platforms.isEmpty) return;

    final isSpanish = (registerCubit.state.language ?? '')
        .toLowerCase()
        .contains('es');

    // 🔹 NUEVO: Mensaje previo mencionando las redes conectadas
    final platformNames = platforms
        .map((p) => p.keys.first.capitalize())
        .join(', ')
        .replaceFirst(
          RegExp(r',\s(?!.*,)'),
          isSpanish ? ' y ' : ' and ',
        ); // último separador

    final introText = isSpanish
        ? '¡Genial! Veo que conectaste $platformNames. 🎉'
        : 'Great! I see you connected $platformNames. 🎉';

    _addMessage({
      "other": true,
      "text": introText,
      "type": MessageType.text,
      "time": _getTimeNow(),
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // 🔹 Luego mostrar las cards
    final socialMessages = SocialCardsHelper.generateSocialCards(
      platforms: platforms,
      isSpanish: isSpanish,
      getTimeNow: _getTimeNow,
    );

    for (final message in socialMessages) {
      _addMessage(message);
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  /// ------------------- Utilidades -------------------
  // Señalar que esperamos confirmación del avatar IG (se activa desde el NavigationHandler)
  void expectInstagramAvatarConfirmation() {
    _awaitingInstagramAvatarConfirm = true;
  }

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
    _isDisposed = true;
    scrollController.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
