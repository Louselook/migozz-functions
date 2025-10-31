// chat_controller.dart (ACTUALIZADO)
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/audio_chat_handler.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/tutorial/avatar_register_tutorial.dart';
import 'package:migozz_app/features/tutorial/voice_register_tutorial.dart';

class ChatController extends ChangeNotifier {
  final RegisterCubit registerCubit;
  ChatController({required this.registerCubit});

  VoidCallback? onResetAudioUI;

  final AvatarTutorialService _avatarTutorialService = AvatarTutorialService();
  void Function()? onShowAvatarTutorial;

  final VoiceNoteTutorialService _voiceNoteTutorialService = VoiceNoteTutorialService();
  void Function()? onShowVoiceNoteTutorial;


  bool _active = true;
  bool get isActive => _active;

  bool _showPhoneInput = false;
  bool get showPhoneInput => _showPhoneInput;

  void Function(Map<String, dynamic> botResponse)? onBotAction;

  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;
  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  final AudioChatHandler _audioHandler = AudioChatHandler();
  List<String> get currentSuggestions => _audioHandler.currentSuggestions;

  void initializeChat({void Function(Map<String, dynamic>)? onActionRequired}) {
    GeminiService.instance.ensureConfigured();
    onBotAction = onActionRequired;
    _active = true;
    showNextBotMessage();
  }

  Future<void> terminateChat({bool clearMessages = false}) async {
    if (!_active) return;
    _active = false;
    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler: $e');
    }
    if (clearMessages) {
      _messages.clear();
    }
    onBotAction = null;
    notifyListeners();
  }

  void onAudioFinished() {
    if (!_active) return;
    _audioHandler.onAudioFinished(
      registerCubit: registerCubit,
      addMessage: addMessage,
    );
    notifyListeners();
  }

  /// Maneja la respuesta del usuario para el paso de ubicación
  /// Opciones: "Sí", "No", "Ubicación incorrecta"
  Future<void> handleLocationResponse(String userResponse) async {
    if (!_active) return;
    
    final normalizedResponse = userResponse.trim().toLowerCase();
    final isSpanish = registerCubit.state.language == 'Español';
    
    debugPrint('📍 [ChatController] Respuesta de ubicación: "$userResponse"');
    
    if (normalizedResponse == 'sí' || normalizedResponse == 'yes' || 
        normalizedResponse == 'si') {
      // ✅ Usuario acepta la ubicación detectada
      debugPrint('📍 [ChatController] Usuario confirmó ubicación');
      registerCubit.confirmLocation();
      
      // Mensaje de confirmación
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
            ? "Perfecto, ubicación confirmada. ✅"
            : "Perfect, location confirmed. ✅",
        "name": "Migozz",
        "time": getTimeNow(),
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_active) return;
      _lastUserMessage = 'location_confirmed';
      await showNextBotMessage();
      
    } else if (normalizedResponse == 'no') {
      // ❌ Usuario rechaza usar ubicación (continúa sin ubicación)
      debugPrint('📍 [ChatController] Usuario rechazó ubicación');
      registerCubit.rejectLocation();
      
      // Mensaje informativo
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
            ? "Entendido, continuaremos sin una ubicación específica."
            : "Understood, we'll continue without a specific location.",
        "name": "Migozz",
        "time": getTimeNow(),
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_active) return;
      _lastUserMessage = 'location_rejected';
      await showNextBotMessage();
      
    } else if (normalizedResponse.contains('incorrecta') || 
               normalizedResponse.contains('incorrect') ||
               normalizedResponse == 'ubicación incorrecta' ||
               normalizedResponse == 'incorrect location') {
      // 🔄 Usuario dice que la ubicación es incorrecta
      debugPrint('📍 [ChatController] Usuario reportó ubicación incorrecta');
      registerCubit.requestCorrectLocation();
      
      // Mensaje pidiendo nueva ubicación
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
            ? "Entendido. Por favor, ingresa tu ubicación manualmente o intenta detectarla nuevamente."
            : "Understood. Please enter your location manually or try detecting it again.",
        "name": "Migozz",
        "time": getTimeNow(),
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_active) return;
      _lastUserMessage = 'location_incorrect';
      await showNextBotMessage();
      
    } else {
      // ⚠️ Respuesta no válida
      debugPrint('⚠️ [ChatController] Respuesta de ubicación no válida: $userResponse');
      
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
            ? "Por favor, selecciona una opción válida: Sí, No, o Ubicación incorrecta."
            : "Please select a valid option: Yes, No, or Incorrect location.",
        "options": isSpanish 
            ? ["Sí", "No", "Ubicación incorrecta"]
            : ["Yes", "No", "Incorrect location"],
        "name": "Migozz",
        "time": getTimeNow(),
      });
    }
    
    notifyListeners();
  }

  Future<void> sendUserAudio(String audioPath) async {
    if (!_active) return;
    await _audioHandler.sendUserAudio(
      audioPath: audioPath,
      registerCubit: registerCubit,
      addMessage: addMessage,
      chatController: this,
      removeTyping: _removeTypingMessage,
    );
    notifyListeners();
  }

  void _removeTypingMessage() {
    if (!_active) return;
    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    notifyListeners();
  }

  Future<void> sendAvatarPhoto(String photoPath) async {
    if (!_active) return;

    debugPrint('📸 Foto de avatar recibida: $photoPath');

    addMessage({
      "other": false,
      "type": MessageType.pictureCard,
      "pictures": [
        {"imageUrl": photoPath, "label": "Mi foto de perfil"},
      ],
      "time": getTimeNow(),
    });

    final isUrl = photoPath.startsWith('http');

    if (isUrl) {
      debugPrint('✅ URL de avatar guardada: $photoPath');
      registerCubit.setAvatarUrl(photoPath);
    } else {
      if (kIsWeb) {
        debugPrint('⚠️ Web: no se puede guardar archivo local en web: $photoPath');
      } else {
        final file = File(photoPath);
        if (await file.exists()) {
          registerCubit.setAvatarFile(file);
          debugPrint('✅ Archivo de avatar guardado localmente: $photoPath');

          // Subir avatar inmediatamente
          final email = registerCubit.state.email;
          if (email != null && email.isNotEmpty) {
            try {
              addMessage({
                "other": true,
                "type": MessageType.typing,
                "name": "Migozz",
                "time": getTimeNow(),
              });

              debugPrint('📤 Subiendo avatar a servidor...');
              
              final mediaService = UserMediaService();
              final urls = await mediaService.uploadFilesTemporarily(
                email: email,
                files: {MediaType.avatar: file},
              );

              final avatarUrl = urls[MediaType.avatar];

              _removeTypingMessage();

              if (avatarUrl != null) {
                debugPrint('✅ Avatar subido exitosamente: $avatarUrl');
                registerCubit.setAvatarUrl(avatarUrl);

                final isSpanish = registerCubit.state.language == 'Español';
                addMessage({
                  "other": true,
                  "type": MessageType.text,
                  "text": isSpanish
                      ? "✅ Foto guardada correctamente"
                      : "✅ Photo saved successfully",
                  "name": "Migozz",
                  "time": getTimeNow(),
                });
              } else {
                debugPrint('❌ No se obtuvo URL del avatar');
              }
            } catch (e) {
              debugPrint('❌ Error subiendo avatar: $e');
              _removeTypingMessage();
            }
          }
        } else {
          debugPrint('❌ Archivo no encontrado: $photoPath');
          return;
        }
      }
    }

    _lastUserMessage = photoPath;

    await Future.delayed(const Duration(milliseconds: 600));
    if (!_active) return;
    await showNextBotMessage();
  }

  Future<void> showNextBotMessage() async {
    if (!_active) return;

    registerCubit.setAiResponse(true);

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
      Map<String, dynamic> botResponse;

      try {
        botResponse = await GeminiService.instance
            .sendMessage(userInput, registerCubit: registerCubit)
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        if (!_active) return;
        _messages.removeWhere((msg) => msg["type"] == MessageType.typing);

        final isSpanish = registerCubit.state.language == 'Español';
        addMessage({
          "other": true,
          "type": MessageType.text,
          "text": isSpanish
              ? "Estoy tardando más de lo normal. Intenta de nuevo, por favor."
              : "I'm taking longer than usual. Please try again.",
          "options": const [],
          "name": "Migozz",
          "time": getTimeNow(),
          "isError": true,
        });
        return;
      }

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

      final step = botResponse["step"]?.toString() ?? '';
      _showPhoneInput =
          step.contains('phone') || botResponse["showPhoneCode"] == true;

      addMessage(message);
      
      if (GeminiService.instance.isOnAvatarStep && !kIsWeb) {
        debugPrint('📸 [ChatController] Detectado paso de avatar');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (onShowAvatarTutorial != null) {
            onShowAvatarTutorial!();
          }
        });
      }

      if (GeminiService.instance.isOnVoiceNoteStep && !kIsWeb) {
        debugPrint('🎤 [ChatController] Detectado paso de voice note, activando tutorial');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (onShowVoiceNoteTutorial != null && _active) {
            onShowVoiceNoteTutorial!();
          }
        });
      }

      // Auto-skip voice step on WEB
      final isVoiceStep = GeminiService.instance.isOnVoiceNoteStep || step.contains('voice');
      if (kIsWeb && isVoiceStep) {
        final isSpanish = registerCubit.state.language == 'Español';

        addMessage({
          "other": true,
          "type": MessageType.text,
          "text": isSpanish
              ? "Estás en la web — usa la app para grabar tu nota de presentación (5-10 segundos)."
              : "You're on the web — please use the app to record your voice note (5-10 seconds).",
          "name": "Migozz",
          "time": getTimeNow(),
        });

        _lastUserMessage = 'skipped_voice_web';

        await Future.delayed(const Duration(milliseconds: 700));
        if (!_active) return;
        await showNextBotMessage();
        return;
      }

      if (!_active) return;

      if (botResponse["explainAndRepeat"] == true) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!_active) return;
        await showNextBotMessage();
        return;
      }

      if (botResponse["autoAdvance"] == true) {
        debugPrint('🎉 Mensaje de éxito detectado, avanzando automáticamente...');
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
      if (!_active) return;
      _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
      final isSpanish = registerCubit.state.language == 'Español';
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
            ? "Ha ocurrido un problema. Intenta de nuevo, por favor."
            : "Something went wrong. Please try again.",
        "options": const [],
        "name": "Migozz",
        "time": getTimeNow(),
        "isError": true,
      });
    } finally {
      if (_active) registerCubit.setAiResponse(false);
      notifyListeners();
    }
  }

  void showAvatarTutorialIfNeeded(BuildContext context) {
    final currentStep = GeminiService.instance.currentStep;
    
    if (currentStep == 'avatarUrl' && onShowAvatarTutorial != null) {
      debugPrint('📸 [ChatController] Mostrando tutorial de avatar');
      
      // Pequeño delay para asegurar que el widget esté renderizado
      Future.delayed(const Duration(milliseconds: 300), () {
        onShowAvatarTutorial?.call();
      });
    }
  }

  Future<void> sendUserMessage(String text) async {
    if (!_active) return;
    if (text.trim().isEmpty) return;

    // Si estamos en el paso de audio y NO estamos esperando confirmación
    if (GeminiService.instance.isOnVoiceNoteStep &&
        !_audioHandler.isWaitingForAudioConfirmation) {
      // ... código existente web ...
      return;
    }

    final audioResponse = _audioHandler.handleAudioConfirmationResponse(text);

    if (audioResponse != null) {
      addMessage({
        "other": false,
        "text": text,
        "type": MessageType.text,
        "time": getTimeNow(),
      });

      if (audioResponse == 'keep') {
        await _audioHandler.confirmAudio(
          registerCubit,
          onResetAudioUI: onResetAudioUI,
          addMessage: addMessage,
        );
        
        _lastUserMessage = registerCubit.state.voiceNoteUrl ?? 
                          registerCubit.voiceNoteFile?.path ?? 
                          text;
        
        await Future.delayed(const Duration(milliseconds: 600));
        if (!_active) return;
        await showNextBotMessage();
      } else if (audioResponse == 'record') {
        final recordMessage = _audioHandler.getRecordAgainMessage(
          registerCubit,
        );
        addMessage(recordMessage);

        onResetAudioUI?.call();

        notifyListeners();
      }
      return;
    }

    _lastUserMessage = text;

    addMessage({
      "other": false,
      "text": text,
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    _showPhoneInput = false;

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
    _active = false;
    _avatarTutorialService.closeTutorial();
    _voiceNoteTutorialService.closeTutorial(); 
    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler en dispose: $e');
    }
    scrollController.dispose();
    super.dispose();
  }
}