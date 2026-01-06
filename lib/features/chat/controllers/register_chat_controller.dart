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
import 'package:migozz_app/features/chat/services/step_input_validator.dart';

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

  // Servicios específicos del registro+
  Future<void> Function()? onRegistrationComplete;
  final AvatarTutorialService _avatarTutorialService = AvatarTutorialService();
  final VoiceNoteTutorialService _voiceNoteTutorialService =
      VoiceNoteTutorialService();
  final AudioChatHandler _audioHandler = AudioChatHandler();

  // IA-01 & IA-02: Step input validation
  late final StepInputValidator _stepInputValidator;
  StepInputValidator get stepInputValidator => _stepInputValidator;

  // Estado específico del registro
  bool _showPhoneInput = false;
  bool get showPhoneInput => _showPhoneInput;

  String? _lastUserMessage;
  String? get lastUserMessage => _lastUserMessage;

  /// Sets the next input that will be sent to the AI on `showNextBotMessage()`.
  /// Useful for navigation-based steps (eg. social ecosystem) where the user
  /// doesn't type anything in chat but we still need to advance the flow.
  void setLastUserMessageForBot(String message) {
    _lastUserMessage = message;
  }

  List<String> get currentSuggestions => _audioHandler.currentSuggestions;

  RegisterChatController({required this.registerCubit, this.firebaseUid}) {
    _stepInputValidator = StepInputValidator(registerCubit: registerCubit);
  }

  /// Inicializar el chat de registro con IA
  void initializeChat({
    void Function(Map<String, dynamic>)? onActionRequired,
    Future<void> Function()? onRegistrationComplete,
  }) {
    GeminiService.instance.ensureConfigured();
    onBotAction = onActionRequired;
    this.onRegistrationComplete = onRegistrationComplete;
    reactivateChat();
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
      clearMessages; // <- CORREGIDO: llamamos el método
    }

    // limpiar callbacks
    onBotAction = null;
    onResetAudioUI = null;
    onShowAvatarTutorial = null;
    onShowVoiceNoteTutorial = null;

    super.terminateChat(); // esperar al padre si hace async
  }

  /// Callback cuando el audio termina de reproducirse
  void onAudioFinished() {
    if (!isActive) return;
    _audioHandler.onAudioFinished(
      registerCubit: registerCubit,
      addMessage: addMessage,
    );
    if (isActive) notifyListeners();
  }

  /// Maneja la respuesta del usuario para el paso de ubicación
  /// Opciones: "Sí", "No"
  Future<void> handleLocationResponse(String userResponse) async {
    if (!isActive) return;

    final normalizedResponse = userResponse.trim().toLowerCase();
    final isSpanish = registerCubit.state.language == 'Español';

    debugPrint('📍 [RegisterChat] Respuesta de ubicación: "$userResponse"');

    if (normalizedResponse == 'sí' ||
        normalizedResponse == 'yes' ||
        normalizedResponse == 'si') {
      // Usuario acepta la ubicación detectada
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
      // En lugar de saltar ubicación, pedir ingreso manual.
      debugPrint('📍 [RegisterChat] Usuario indicó que no es correcta');

      addOtherMessage(
        text: isSpanish
            ? "De acuerdo. Escribe tu ubicación manualmente como: País, Ciudad, Estado/Departamento.\nEj: Colombia, Medellín, Antioquia"
            : "Okay. Type your location manually as: Country, City, State/Region.\nExample: Colombia, Medellin, Antioquia",
        name: "Migozz",
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!isActive) return;
      _lastUserMessage = 'no';
      await showNextBotMessage();
    } else if (normalizedResponse.contains('incorrecta') ||
        normalizedResponse.contains('incorrect') ||
        normalizedResponse == 'incorrect location') {
      // Aunque ya no mostramos esta opción, si el usuario lo escribe, dirigir a ingreso manual.
      debugPrint('📍 [RegisterChat] Usuario escribió ubicación incorrecta');

      addOtherMessage(
        text: isSpanish
            ? "Entendido. Escribe tu ubicación manualmente como: País, Ciudad, Estado/Departamento.\nEj: Colombia, Medellín, Antioquia"
            : "Got it. Type your location manually as: Country, City, State/Region.\nExample: Colombia, Medellin, Antioquia",
        name: "Migozz",
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!isActive) return;
      await showNextBotMessage();
    } else {
      // Respuesta no válida
      debugPrint(
        '⚠️ [RegisterChat] Respuesta de ubicación no válida: $userResponse',
      );

      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": isSpanish
          ? "Por favor, selecciona una opción válida: Sí o No."
          : "Please select a valid option: Yes or No.",
        "options": isSpanish ? ["Sí", "No"] : ["Yes", "No"],
        "name": "Migozz",
        "time": getTimeNow(),
      });
    }

    if (isActive) notifyListeners();
  }

  /// Enviar audio del usuario
  Future<void> sendUserAudio(String audioPath) async {
    if (!isActive) return;

    // IA-02: Validate audio input for current step
    final (isValid, errorMsg) = _stepInputValidator.validateAudioInput();
    if (!isValid && errorMsg != null) {
      debugPrint('⚠️ [RegisterChat] Audio rejected: $errorMsg');
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": errorMsg,
        "name": "Migozz",
        "time": getTimeNow(),
      });
      if (isActive) notifyListeners();
      return;
    }

    await _audioHandler.sendUserAudio(
      audioPath: audioPath,
      registerCubit: registerCubit,
      addMessage: addMessage,
      chatController: this,
      removeTyping: _removeTypingMessage,
    );
    if (isActive) notifyListeners();
  }

  /// Remover mensaje de "escribiendo..."
  void _removeTypingMessage() {
    if (!isActive) return;
    removeTypingIndicator(); // Usar método heredado
  }

  /// Enviar foto de avatar
  Future<void> sendAvatarPhoto(String photoPath) async {
    if (!isActive) return;

    // IA-01: Validate image input for current step
    final (isValid, errorMsg) = _stepInputValidator.validateImageInput();
    if (!isValid && errorMsg != null) {
      debugPrint('⚠️ [RegisterChat] Image rejected: $errorMsg');
      addMessage({
        "other": true,
        "type": MessageType.text,
        "text": errorMsg,
        "name": "Migozz",
        "time": getTimeNow(),
      });
      if (isActive) notifyListeners();
      return;
    }

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

      // Protege campos que podrían ser null
      final botText = (botResponse["text"]?.toString() ?? '');
      // final botOptions = botResponse["options"] ?? [];
      final botStep = botResponse["step"]?.toString() ?? '';
      final botValid = botResponse["valid"];
      final botAction = botResponse["action"];
      final botIsError = botResponse["isError"] == true;
      final botProfilePictures = botResponse["profilePictures"];
      final rawBotOptions = botResponse["options"];
      // Build safe list of labels for the bot/UI that expects String list
      final safeBotOptions = <String>[];
      if (rawBotOptions is List) {
        for (final o in rawBotOptions) {
          if (o == null) continue;
          if (o is String) {
            safeBotOptions.add(o);
          } else if (o is Map) {
            final label = (o['label'] ?? o['text'])?.toString() ?? o.toString();
            safeBotOptions.add(label);
          } else {
            safeBotOptions.add(o.toString());
          }
        }
      }

      final message = {
        "other": true,
        "type": MessageType.text,
        "text": botText,
        "options": safeBotOptions, // <- siempre List<String>
        "rawOptions":
            rawBotOptions, // <- original (List<dynamic>) para UI si quiere actions
        "step": botStep,
        "valid": botValid,
        "action": botAction,
        "name": "Migozz",
        "time": getTimeNow(),
      };

      if (botIsError) {
        message["isError"] = true;
      }
      if (botProfilePictures != null) {
        message["profilePictures"] = botProfilePictures;
      }

      _showPhoneInput =
          botStep.contains('phone') || botResponse["showPhoneCode"] == true;

      addMessage(message);

      // COPY de callbacks / flags para evitar race conditions
      final bool isOnAvatarStep = GeminiService.instance.isOnAvatarStep;
      final bool isOnVoiceNoteStep = GeminiService.instance.isOnVoiceNoteStep;
      final localOnShowAvatarTutorial = onShowAvatarTutorial;
      final localOnShowVoiceNoteTutorial = onShowVoiceNoteTutorial;
      final localOnBotAction = onBotAction;
      final isWeb = kIsWeb;
      final isSpanish = registerCubit.state.language == 'Español';

      // Mostrar tutorial avatar
      if (isOnAvatarStep && !isWeb) {
        debugPrint('📸 [RegisterChat] Detectado paso de avatar');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isActive) return;
          if (localOnShowAvatarTutorial != null) {
            try {
              localOnShowAvatarTutorial();
            } catch (e, st) {
              debugPrint('Error en avatar tutorial callback: $e\n$st');
            }
          }
        });
      }

      // Mostrar tutorial voice note
      // NOTA: No mostrar tutorial automáticamente para voiceNoteUrl
      // El usuario verá opciones de Skip y podrá elegir grabar si quiere
      // El tutorial se mostrará más adelante cuando esté listo para grabar
      if (isOnVoiceNoteStep && !isWeb) {
        debugPrint(
          '🎤 [RegisterChat] Detectado paso de voice note - Opciones disponibles',
        );
        // Tutorial removido - las opciones se mostrarán sin obstrucciones
      }

      // Auto-skip voice step en WEB
      final isVoiceStep = isOnVoiceNoteStep || botStep.contains('voice');
      if (isWeb && isVoiceStep) {
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

      // Repetir la pregunta si se mostró explicación (WHY explanation) o Q&A general
      if (botResponse["repeatQuestion"] == true) {
        debugPrint('🔄 [RegisterChat] Volviendo a preguntar el mismo campo...');
        // Limpiar input anterior si se indica
        if (botResponse["clearInput"] == true) {
          _lastUserMessage = '';
          debugPrint(
            '🗑️ [RegisterChat] Input limpiado para evitar re-procesar',
          );
        }
        await Future.delayed(const Duration(milliseconds: 700));
        if (!isActive) return;
        // No incrementar índice, volver a mostrar la misma pregunta
        await showNextBotMessage();
        return;
      }

      // Auto-avanzar si el bot lo indica (explainAndRepeat)
      if (botResponse["explainAndRepeat"] == true) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!isActive) return;
        await showNextBotMessage();
        return;
      }

      // AutoAdvance (por ejemplo: "registro completado")
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

      final stepStr = botResponse["step"]?.toString() ?? '';

      // Si el bot indica que el flujo terminó, llamamos al callback de registro
      if (stepStr == 'finished' ||
          botResponse["action"] == 'complete_registration') {
        debugPrint(
          '🎯 [RegisterChat] Bot indica FIN del flujo, disparando registro final...',
        );
        final localComplete = onRegistrationComplete;
        if (localComplete != null) {
          // ejecutarlo sin bloquear el hilo principal del showNextBotMessage
          Future.microtask(() async {
            try {
              await localComplete();
            } catch (e, st) {
              debugPrint('❌ Error en onRegistrationComplete: $e\n$st');
            }
          });
        } else {
          debugPrint(
            '⚠️ onRegistrationComplete no está definido; nadie completará el registro automáticamente.',
          );
        }
      }

      // Ejecutar acción del bot si existe callback (USANDO LA COPIA localOnBotAction)
      if (localOnBotAction != null) {
        Future.delayed(const Duration(milliseconds: 850), () {
          if (!isActive) return;
          try {
            localOnBotAction(botResponse);
          } catch (e, st) {
            debugPrint('Error al ejecutar onBotAction: $e\n$st');
          }
        });
      }
    } catch (e, st) {
      debugPrint('❌ Error en showNextBotMessage: $e');
      debugPrintStack(label: 'stack', stackTrace: st);
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
      if (isActive) {
        try {
          registerCubit.setAiResponse(false);
        } catch (_) {}
        notifyListeners();
      } else {
        // Si ya no está activo, solo limpia estado si el cubit lo requiere (safe)
        try {
          registerCubit.setAiResponse(false);
        } catch (_) {}
      }
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
    // PERO permite que "Skip" u otros mensajes se procesen normalmente
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

      // Si el usuario envía "Skip" o cualquier otro texto, permitir que se procese
      // No hacer return aquí, dejar que continúe el flujo normal
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
        if (isActive) notifyListeners();
      }
      return;
    }

    // Mensaje normal de texto
    _lastUserMessage = text;

    // Limpiar chips (options/suggestions) del último mensaje del bot
    // para evitar que se solapen con el nuevo mensaje del usuario.
    for (final msg in messages.reversed) {
      if (msg["other"] == true) {
        if (msg["options"] != null) msg["options"] = [];
        if (msg["suggestions"] != null) msg["suggestions"] = [];
        break;
      }
    }

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
    debugPrint('🎯 [RegisterChat] Sugerencia seleccionada: $suggestion');
    sendTextMessage(suggestion);

    // Limpiar opciones del último mensaje del bot
    for (var msg in messages.reversed) {
      if (msg["other"] == true && msg["options"] != null) {
        msg["options"] = [];
        msg["suggestions"] = []; // Limpiar sugerencias también
        break;
      }
    }
    if (isActive) notifyListeners();
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

    // limpiar cualquier referencia/callback para evitar llamadas luego de dispose
    onBotAction = null;
    onResetAudioUI = null;
    onShowAvatarTutorial = null;
    onShowVoiceNoteTutorial = null;

    super.dispose(); // Llamar al dispose del padre al final
  }
}
