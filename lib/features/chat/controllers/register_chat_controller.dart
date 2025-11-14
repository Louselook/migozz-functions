import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/chat/controllers/generic_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/audio_chat_handler.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/tutorial/avatar_register_tutorial.dart';
import 'package:migozz_app/features/tutorial/voice_register_tutorial.dart';

/// Controlador específico para el chat de registro con IA
/// Extiende GenericChatController y agrega funcionalidad de Gemini AI
class RegisterChatController extends GenericChatController {
  final RegisterCubit registerCubit;
  final String? firebaseUid;

  // Callbacks específicos del registro
  VoidCallback? onResetAudioUI;
  void Function()? onShowAvatarTutorial;
  void Function()? onShowVoiceNoteTutorial;
  void Function(Map<String, dynamic> botResponse)? onBotAction;

  // Servicios específicos del registro
  final AvatarTutorialService _avatarTutorialService = AvatarTutorialService();
  final VoiceNoteTutorialService _voiceNoteTutorialService =
      VoiceNoteTutorialService();
  final AudioChatHandler _audioHandler = AudioChatHandler();

  // Estado específico del registro
  bool _showPhoneInput = false;
  bool get showPhoneInput => _showPhoneInput;

  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  List<String> get currentSuggestions => _audioHandler.currentSuggestions;

  RegisterChatController({required this.registerCubit, this.firebaseUid});

  /// Inicializar el chat de registro con IA
  void initializeChat({void Function(Map<String, dynamic>)? onActionRequired}) {
    GeminiService.instance.ensureConfigured();
    onBotAction = onActionRequired;
    reactivateChat(); // Usar método heredado
    showNextBotMessage();
  }

  /// Terminar el chat de registro
  @override
  Future<void> terminateChat({bool clearMessages = false}) async {
    if (!isActive) return;

    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler: $e');
    }

    if (clearMessages) {
      clearMessages;
    }

    onBotAction = null;
    super.terminateChat(); // Usar método heredado
  }

  /// Callback cuando el audio termina de reproducirse
  void onAudioFinished() {
    if (!isActive) return;
    _audioHandler.onAudioFinished(
      registerCubit: registerCubit,
      addMessage: addMessage,
    );
    notifyListeners();
  }

  /// Maneja la respuesta del usuario para el paso de ubicación
  /// Opciones: "Sí", "No", "Ubicación incorrecta"
  Future<void> handleLocationResponse(String userResponse) async {
    if (!isActive) return;

    final normalizedResponse = userResponse.trim().toLowerCase();
    final isSpanish = registerCubit.state.language == 'Español';

    debugPrint('📍 [RegisterChat] Respuesta de ubicación: "$userResponse"');

    if (normalizedResponse == 'sí' ||
        normalizedResponse == 'yes' ||
        normalizedResponse == 'si') {
      // ✅ Usuario acepta la ubicación detectada
      debugPrint('📍 [RegisterChat] Usuario confirmó ubicación');
      registerCubit.confirmLocation();

      addOtherMessage(
        text: isSpanish
            ? "Perfecto, ubicación confirmada. ✅"
            : "Perfect, location confirmed. ✅",
        name: "Migozz",
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!isActive) return;
      _lastUserMessage = 'location_confirmed';
      await showNextBotMessage();
    } else if (normalizedResponse == 'no') {
      // ❌ Usuario rechaza usar ubicación
      debugPrint('📍 [RegisterChat] Usuario rechazó ubicación');
      registerCubit.rejectLocation();

      addOtherMessage(
        text: isSpanish
            ? "Entendido, continuaremos sin una ubicación específica."
            : "Understood, we'll continue without a specific location.",
        name: "Migozz",
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!isActive) return;
      _lastUserMessage = 'location_rejected';
      await showNextBotMessage();
    } else if (normalizedResponse.contains('incorrecta') ||
        normalizedResponse.contains('incorrect') ||
        normalizedResponse == 'ubicación incorrecta' ||
        normalizedResponse == 'incorrect location') {
      // 🔄 Usuario dice que la ubicación es incorrecta
      debugPrint('📍 [RegisterChat] Usuario reportó ubicación incorrecta');
      registerCubit.requestCorrectLocation();

      addOtherMessage(
        text: isSpanish
            ? "Entendido. Por favor, ingresa tu ubicación manualmente o intenta detectarla nuevamente."
            : "Understood. Please enter your location manually or try detecting it again.",
        name: "Migozz",
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!isActive) return;
      _lastUserMessage = 'location_incorrect';
      await showNextBotMessage();
    } else {
      // ⚠️ Respuesta no válida
      debugPrint(
        '⚠️ [RegisterChat] Respuesta de ubicación no válida: $userResponse',
      );

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

  /// Enviar audio del usuario
  Future<void> sendUserAudio(String audioPath) async {
    if (!isActive) return;
    await _audioHandler.sendUserAudio(
      audioPath: audioPath,
      registerCubit: registerCubit,
      addMessage: addMessage,
      chatController: this,
      removeTyping: _removeTypingMessage,
    );
    notifyListeners();
  }

  /// Remover mensaje de "escribiendo..."
  void _removeTypingMessage() {
    if (!isActive) return;
    removeTypingIndicator(); // Usar método heredado
  }

  /// Enviar foto de avatar
  Future<void> sendAvatarPhoto(String photoPath) async {
    if (!isActive) return;

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
        debugPrint(
          '⚠️ Web: no se puede guardar archivo local en web: $photoPath',
        );
      } else {
        final file = File(photoPath);
        if (await file.exists()) {
          registerCubit.setAvatarFile(file);
          debugPrint('✅ Archivo de avatar guardado localmente: $photoPath');

          // Subir avatar inmediatamente
          final email = registerCubit.state.email;
          if (email != null && email.isNotEmpty) {
            try {
              showTypingIndicator(name: "Migozz"); // Usar método heredado

              debugPrint('📤 Subiendo avatar a servidor...');

              final mediaService = UserMediaService();
              final urls = await mediaService.uploadFilesTemporarily(
                email: email,
                files: {MediaType.avatar: file},
              );

              final avatarUrl = urls[MediaType.avatar];

              removeTypingIndicator(); // Usar método heredado

              if (avatarUrl != null) {
                debugPrint('✅ Avatar subido exitosamente: $avatarUrl');
                registerCubit.setAvatarUrl(avatarUrl);

                final isSpanish = registerCubit.state.language == 'Español';
                addOtherMessage(
                  text: isSpanish
                      ? "✅ Foto guardada correctamente"
                      : "✅ Photo saved successfully",
                  name: "Migozz",
                );
              } else {
                debugPrint('❌ No se obtuvo URL del avatar');
              }
            } catch (e) {
              debugPrint('❌ Error subiendo avatar: $e');
              removeTypingIndicator();
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
    if (!isActive) return;
    await showNextBotMessage();
  }

  /// Mostrar siguiente mensaje del bot (IA)
  Future<void> showNextBotMessage() async {
    if (!isActive) return;

    registerCubit.setAiResponse(true);

    if (isActive) {
      showTypingIndicator(name: "Migozz"); // Usar método heredado
    }

    try {
      final userInput = _lastUserMessage ?? '';
      Map<String, dynamic> botResponse;

      try {
        botResponse = await GeminiService.instance
            .sendMessage(userInput, registerCubit: registerCubit)
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        if (!isActive) return;
        removeTypingIndicator(); // Usar método heredado

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

      if (!isActive) return;

      removeTypingIndicator(); // Usar método heredado

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

      // Mostrar tutorial de avatar si es necesario
      if (GeminiService.instance.isOnAvatarStep && !kIsWeb) {
        debugPrint('📸 [RegisterChat] Detectado paso de avatar');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (onShowAvatarTutorial != null) {
            onShowAvatarTutorial!();
          }
        });
      }

      // Mostrar tutorial de voice note si es necesario
      if (GeminiService.instance.isOnVoiceNoteStep && !kIsWeb) {
        debugPrint('🎤 [RegisterChat] Detectado paso de voice note');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (onShowVoiceNoteTutorial != null && isActive) {
            onShowVoiceNoteTutorial!();
          }
        });
      }

      // Auto-skip voice step en WEB
      final isVoiceStep =
          GeminiService.instance.isOnVoiceNoteStep || step.contains('voice');
      if (kIsWeb && isVoiceStep) {
        final isSpanish = registerCubit.state.language == 'Español';

        addOtherMessage(
          text: isSpanish
              ? "Estás en la web — usa la app para grabar tu nota de presentación (1-10 segundos)."
              : "You're on the web — please use the app to record your voice note (1-10 seconds).",
          name: "Migozz",
        );

        _lastUserMessage = 'skipped_voice_web';

        await Future.delayed(const Duration(milliseconds: 700));
        if (!isActive) return;
        await showNextBotMessage();
        return;
      }

      if (!isActive) return;

      // Auto-avanzar si el bot lo indica
      if (botResponse["explainAndRepeat"] == true) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!isActive) return;
        await showNextBotMessage();
        return;
      }

      if (botResponse["autoAdvance"] == true) {
        debugPrint(
          '🎉 Mensaje de éxito detectado, avanzando automáticamente...',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!isActive) return;
        _lastUserMessage = 'continue';
        await showNextBotMessage();
        return;
      }

      // Ejecutar acción del bot si existe callback
      if (onBotAction != null) {
        Future.delayed(const Duration(milliseconds: 850), () {
          if (!isActive) return;
          onBotAction!(botResponse);
        });
      }
    } catch (e) {
      debugPrint('❌ Error en showNextBotMessage: $e');
      if (!isActive) return;
      removeTypingIndicator();
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
      if (isActive) registerCubit.setAiResponse(false);
      notifyListeners();
    }
  }

  /// Mostrar tutorial de avatar si es necesario
  void showAvatarTutorialIfNeeded(BuildContext context) {
    final currentStep = GeminiService.instance.currentStep;

    if (currentStep == 'avatarUrl' && onShowAvatarTutorial != null) {
      debugPrint('📸 [RegisterChat] Mostrando tutorial de avatar');
      Future.delayed(const Duration(milliseconds: 300), () {
        onShowAvatarTutorial?.call();
      });
    }
  }

  /// Sobrescribir método de envío de mensajes para incluir lógica de IA
  @override
  Future<void> sendTextMessage(String text, {String? userId}) async {
    if (!isActive) return;
    if (text.trim().isEmpty) return;

    // Si estamos en el paso de audio y NO estamos esperando confirmación
    if (GeminiService.instance.isOnVoiceNoteStep &&
        !_audioHandler.isWaitingForAudioConfirmation) {
      // En web, mostrar mensaje de que debe usar la app
      if (kIsWeb) {
        addMessage({
          "other": false,
          "text": text,
          "type": MessageType.text,
          "time": getTimeNow(),
        });
        return;
      }
      return;
    }

    // Manejar respuesta de confirmación de audio
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
          firebaseUid: firebaseUid,
        );

        _lastUserMessage =
            registerCubit.state.voiceNoteUrl ??
            registerCubit.voiceNoteFile?.path ??
            text;

        await Future.delayed(const Duration(milliseconds: 600));
        if (!isActive) return;
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

    // Mensaje normal de texto
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

  /// Manejar selección de sugerencias (chips)
  void onSuggestionSelected(String suggestion) {
    if (!isActive) return;
    sendTextMessage(suggestion);

    // Limpiar opciones del último mensaje del bot
    for (var msg in messages.reversed) {
      if (msg["other"] == true && msg["options"] != null) {
        msg["options"] = [];
        break;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _avatarTutorialService.closeTutorial();
    _voiceNoteTutorialService.closeTutorial();
    try {
      _audioHandler.reset();
    } catch (e) {
      debugPrint('Error al resetear audioHandler en dispose: $e');
    }
    super.dispose(); // Llamar al dispose del padre
  }
}
