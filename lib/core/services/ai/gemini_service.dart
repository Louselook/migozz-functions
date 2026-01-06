import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:migozz_app/core/services/ai/assistant_functions.dart';
import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
import 'package:migozz_app/core/services/ai/migozz_context.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class GeminiService {
  GeminiService._privateConstructor();
  static final GeminiService instance = GeminiService._privateConstructor();

  String _language = 'English';
  GenerativeModel? _model;
  ChatSession? _session;
  static const Duration _enrichTimeout = Duration(seconds: 8);
  String _modelName = 'gemini-2.0-flash';
  double _temperature = 0.4;
  int _maxOutputTokens = 180;
  bool _allowRuntimeSwitch = false;

  void ensureConfigured() {
    if (_model != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('GeminiService: GEMINI_API_KEY missing; AI text disabled.');
      }
      return;
    }
    try {
      final envModel = dotenv.env['GEMINI_MODEL'];
      if (envModel != null && envModel.trim().isNotEmpty) {
        _modelName = envModel.trim();
      }
      final envAllowSwitch = dotenv.env['GEMINI_ALLOW_RUNTIME_SWITCH'];
      if (envAllowSwitch != null) {
        final v = envAllowSwitch.toLowerCase();
        _allowRuntimeSwitch = v == '1' || v == 'true' || v == 'yes';
      }
      final envTemp = dotenv.env['GEMINI_TEMPERATURE'];
      if (envTemp != null) {
        final t = double.tryParse(envTemp);
        if (t != null) _temperature = t;
      }
      final envMax = dotenv.env['GEMINI_MAX_TOKENS'];
      if (envMax != null) {
        final m = int.tryParse(envMax);
        if (m != null) _maxOutputTokens = m;
      }

      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: _temperature,
          maxOutputTokens: _maxOutputTokens,
        ),
      );
      _session = _model!.startChat();
      if (kDebugMode) {
        debugPrint(
          'GeminiService configured. model=$_modelName temp=$_temperature maxTokens=$_maxOutputTokens',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('GeminiService config error: $e');
    }
  }

    int _currentQuestionIndex = 0;
    // Índice donde el usuario estaba cuando pidió repetir/cambiar un campo anterior.
    // Al terminar el cambio, continuamos con el flujo normal desde el siguiente step.
    int _previousQuestionIndex = 0;
    bool _isInRepeatMode = false; // Flag para indicar que estamos en modo repetición
  bool _awaitingEmailChange =
      false; // Flag para rastrear si estamos esperando cambio de email
  bool _comingFromOTPEmailChange =
      false; // Flag para saber si viene de cambio de email desde OTP
    bool _awaitingManualLocation =
      false; // Flag para rastrear si estamos esperando ubicación manual

  // Flujo completo para usuarios NO autenticados
  final List<String> _questionFlowNotAuth = [
    'fullName', // 1
    'username', // 2
    'location', // 3
    'sendOTP', // 4
    'emailVerification', // 5
    'otpInput', // 6
    'emailSuccess', // 7
    'socialEcosystem', // 8
    'avatarUrl', // 9
    'phone', // 10
    'voiceNoteUrl', // 11
  ];

  //  Flujo reducido para usuarios autenticados
  final List<String> _questionFlowAuth = [
    // 'language', // 0
    // 'gender', // 1
    'location', // 3
    'phone', // 4
    'voiceNoteUrl', // 5
    'socialEcosystem', // 2
    // 'category', // 6
  ];

  // Getter dinámico que devuelve el flujo correcto según auth
  List<String> get questionFlow {
    final user = FirebaseAuth.instance.currentUser;

    // flujo reducido si autenticado
    if (user != null) {
      debugPrint('🔑 Usuario autenticado - usando flujo reducido');
      final flow = List<String>.from(_questionFlowAuth);
      if (kIsWeb) {
        flow.removeWhere(
          (step) => step == 'voiceNoteUrl' || step == 'avatarUrl',
        );
      }
      return flow;
    }

    // flujo completo si NO autenticado
    debugPrint('🆕 Usuario no autenticado - usando flujo completo');
    final flow = List<String>.from(_questionFlowNotAuth);
    if (kIsWeb) {
      flow.removeWhere((step) => step == 'voiceNoteUrl' || step == 'avatarUrl');
    }
    return flow;
  }

  // GETTERS PÚBLICOS
  String get currentStep {
    if (_currentQuestionIndex >= 0 &&
        _currentQuestionIndex < questionFlow.length) {
      return questionFlow[_currentQuestionIndex];
    }
    return 'unknown';
  }

  bool get isOnVoiceNoteStep => currentStep == 'voiceNoteUrl';
  bool get isOnPhoneStep => currentStep == 'phone';
  bool get isOnAvatarStep => currentStep == 'avatarUrl';
  int get currentQuestionIndex => _currentQuestionIndex;

  String get currentLanguage => _language;
  void setLanguage(String lang) {
    _language = lang;
    debugPrint('🌐 Idioma establecido: $_language');
  }

  void setStartIndex(int index) {
    if (index >= 0 && index < questionFlow.length) {
      _currentQuestionIndex = index;
      debugPrint('📍 Índice inicial: $index (${questionFlow[index]})');
    }
  }

  void reset() {
    _currentQuestionIndex = 0;
    _previousQuestionIndex = 0;
    _isInRepeatMode = false;
  }

  void setModel(String modelName, {double? temperature, int? maxTokens}) {
    if (!_allowRuntimeSwitch) {
      if (kDebugMode) {
        debugPrint(
          'GeminiService: runtime model switch is disabled. Set GEMINI_ALLOW_RUNTIME_SWITCH=true to enable.',
        );
      }
      return;
    }
    final newName = modelName.trim();
    if (newName.isEmpty) return;
    final changed =
        newName != _modelName ||
        (temperature != null && temperature != _temperature) ||
        (maxTokens != null && maxTokens != _maxOutputTokens);
    if (!changed) return;

    _modelName = newName;
    if (temperature != null) _temperature = temperature;
    if (maxTokens != null) _maxOutputTokens = maxTokens;

    _model = null;
    _session = null;
    if (kDebugMode) {
      debugPrint(
        'GeminiService switching model to $_modelName (temp=$_temperature, maxTokens=$_maxOutputTokens)...',
      );
    }
    ensureConfigured();
  }

  String get currentModel => _modelName;

  Future<Map<String, dynamic>> sendMessage(
    String userInput, {
    required RegisterCubit registerCubit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Sincronizar idioma desde el cubit si está disponible
    final rcLang = registerCubit.state.language;
    if (rcLang != null && rcLang.isNotEmpty) {
      setLanguage(rcLang);
    }

    if (userInput.trim().isEmpty) {
      final q = AssistantFunctions.getCurrentQuestion(
        questionFlow,
        _currentQuestionIndex,
        registerCubit,
      );

      // Si q es null, no prepares nada: termina flujo
      if (q == null) {
        return {
          "text": registerCubit.state.language == 'Español'
              ? "¡Listo! Ya terminamos tu registro 🎉"
              : "All set! Your registration is complete 🎉",
          "options": [],
          "step": "finished",
          "keepTalk": false,
        };
      }

      return await _prepareQuestion(q, registerCubit);
    }

    // Evaluar respuesta
    final currentStepKey = _awaitingManualLocation
      ? 'locationManual'
      : (_awaitingEmailChange
        ? 'emailChange'
        : questionFlow[_currentQuestionIndex]);

    final decision = AssistantFunctions.evaluateUserResponse(
      userInput,
      currentStepKey,
      registerCubit,
    );

    debugPrint('🤖 Decisión: $decision');

    // MANEJO ESPECIAL: Si el usuario pregunta "WHY/POR QUÉ" sobre un campo
    if (decision['isWhy'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      final fieldKey = decision['field'] as String? ?? currentStepKey;

      // Obtener la explicación completa del contexto
      final explanation = MigozzContext.getWhyExplanation(
        fieldKey,
        isSpanish ? 'es' : 'en',
      );

      debugPrint('💡 Usuario preguntó "WHY" - lanzando explicación contextual');

      if (explanation.isNotEmpty) {
        // Si estamos esperando ubicación manual, re-pedir el formato manual
        // (no repetir la pregunta de confirmación de ubicación).
        if (_awaitingManualLocation && currentStepKey == 'locationManual') {
          final manualReprompt = isSpanish
              ? "\n\nAhora escribe tu ubicación como:\nPaís, Ciudad, Estado/Departamento\nEj: Colombia, Medellín, Antioquia"
              : "\n\nNow type your location as:\nCountry, City, State/Region\nExample: Colombia, Medellin, Antioquia";

          return {
            "text": explanation + manualReprompt,
            "options": const <String>[],
            "step": 'regProgress.location',
            "keepTalk": false,
            "clearInput": true,
            "suggestions": const <Map<String, dynamic>>[],
            "keyboardType": "text",
            "manualLocationPrompt": true,
          };
        }

        // Agregar sufijo a la explicación para re-pedir la respuesta
        final reprompt = isSpanish
            ? "\n\n¿Podrías responder la pregunta anterior, por favor?"
            : "\n\nNow, could you answer the question please?";

        // Devolver la explicación sin keepTalk para evitar loop
        // El sistema procesará esto normalmente sin re-evaluar la entrada
        return {
          "text": explanation + reprompt,
          "options": const <String>[],
          "step": 'regProgress.$currentStepKey',
          "keepTalk": false,
          "repeatQuestion": true, // Flag para que IaChatScreen re-pregunte
          "clearInput": true, // Limpiar input para evitar re-procesar
          "suggestions": [], // Limpiar sugerencias
        };
      }
    }

    // MANEJO ESPECIAL: Solicitud de ubicación manual
    if (decision['manualLocationRequest'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      _awaitingManualLocation = true;
      return {
        "text": isSpanish
            ? "Entendido. Escribe tu ubicación manualmente (solo país, ciudad y estado/departamento) como:\nPaís, Ciudad, Estado/Departamento\nEj: Colombia, Medellín, Antioquia"
            : "Got it. Type your location manually (only country, city and state/region) as:\nCountry, City, State/Region\nExample: Colombia, Medellin, Antioquia",
        "options": const <String>[],
        "step": 'regProgress.location',
        "keepTalk": false,
        "keyboardType": "text",
        "manualLocationPrompt": true,
      };
    }

    // MANEJO ESPECIAL: Si el usuario quiere cambiar una respuesta anterior
    if (decision['changeRequest'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      final targetField = decision['targetField'] as String?;
      final isBlocked = decision['blocked'] == true;

      // Si el cambio está bloqueado, mostrar mensaje sin permitir cambio
      if (isBlocked) {
        final blockMessage = decision['message'] as String? ??
            (isSpanish
                ? '⚠️ Tu correo ya ha sido verificado. No puedes cambiar de nuevo.'
                : '⚠️ Your email has already been verified. You cannot change it again.');

        return {
          "text": blockMessage,
          "options": <String>[],
          "step": 'regProgress.emailVerification',
          "keepTalk": false,
        };
      }

      if (targetField != null) {
        // El usuario indicó específicamente qué cambiar
        final fieldIndex = questionFlow.indexOf(targetField);
        if (fieldIndex >= 0) {
          // IMPORTANTE: Guardar el índice actual ANTES de cambiar
          // (para continuar desde el siguiente step al finalizar)
          _previousQuestionIndex = _currentQuestionIndex;
          _isInRepeatMode = true;

          _currentQuestionIndex = fieldIndex;
          debugPrint(
            '🔄 Entrando en modo repetición: $targetField (índice $fieldIndex) | Volverá al índice $_previousQuestionIndex',
          );

          return await _prepareQuestion(
            AssistantFunctions.getCurrentQuestion(
                  questionFlow,
                  _currentQuestionIndex,
                  registerCubit,
                ) ??
                {},
            registerCubit,
          );
        }
      } else {
        // El usuario quiere cambiar algo pero no especificó qué
        // Mostrar un mensaje amigable preguntando qué cambiar
        final message =
            decision['message'] as String? ??
            (isSpanish
                ? "¿Qué información necesitas actualizar? (nombre, usuario, correo, ubicación, teléfono)"
                : "What would you like to update? (name, username, email, location, phone)");

        return {
          "text": message,
          "options": <String>[],
          "step": 'regProgress.changeRequest',
          "keepTalk": false,
        };
      }
    }

    // MANEJO ESPECIAL: Si la respuesta está bloqueada (ej: cambiar email después de verificar)
    if (decision['blocked'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      final blockMessage = decision['message'] as String? ??
          (isSpanish
              ? '⚠️ Tu correo ya ha sido verificado. No puedes cambiar de nuevo.'
              : '⚠️ Your email has already been verified. You cannot change it again.');

      return {
        "text": blockMessage,
        "options": <String>[],
        "step": 'regProgress.$currentStepKey',
        "keepTalk": false,
      };
    }

    // SI ES VÁLIDO → PROCESAR Y VERIFICAR
    if (decision['valid'] == true) {
      // Si veníamos de ubicación manual, limpiar flag al validar
      if (_awaitingManualLocation && currentStepKey == 'locationManual') {
        _awaitingManualLocation = false;
      }
      if (kIsWeb &&
          (currentStepKey == 'voiceNoteUrl' || currentStepKey == 'avatarUrl')) {
        final isSpanish = registerCubit.state.language == 'Español';
        final skipMessage = isSpanish
            ? 'Si deseas añadir tu foto o nota de voz, usa la app móvil 😉'
            : 'If you want to add your photo or voice note, please use the mobile app 😉';

        // Mostrar mensaje y avanzar
        _currentQuestionIndex++;
        if (_currentQuestionIndex >= questionFlow.length) {
          debugPrint('🎉 Registro completado, no hay más preguntas.');
          return {
            "text": registerCubit.state.language == 'Español'
                ? "¡Listo! Ya terminamos tu registro 🎉"
                : "All set! Your registration is complete 🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }
        var nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        // Saltar posibles mensajes "keepTalk"
        while (nextQuestion?['keepTalk'] == true) {
          debugPrint(
            '⏩ Saltando mensaje keepTalk (web): ${questionFlow[_currentQuestionIndex]}',
          );
          _currentQuestionIndex++;
          if (_currentQuestionIndex >= questionFlow.length) break;

          nextQuestion = AssistantFunctions.getCurrentQuestion(
            questionFlow,
            _currentQuestionIndex,
            registerCubit,
          );
        }
        // Retornamos el mensaje indicando el salto
        return {
          "text": skipMessage,
          "options": const <String>[],
          "step": 'regProgress.$currentStepKey',
          "keepTalk": true,
          "explainAndRepeat": false,
        };
      }
      final processResult = await processBotResponse(
        decision,
        registerCubit: registerCubit,
      );

      if (processResult != null && processResult['error'] == true) {
        debugPrint('❌ Error en procesamiento: ${processResult['message']}');

        if (processResult['invalidOTP'] == true) {
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "text": processResult['message'],
            "options": isSpanish
                ? ["Reenviar código", "Cambiar correo"]
                : ["Resend code", "Change email"],
            "step": "regProgress.emailVerification",
            "keepTalk": false,
            "keyboardType": "number",
            "isError": true,
          };
        }

        return processResult;
      }

      // Manejar cambio de email: cuando usuario dice "No" en sendOTP
      if (processResult != null && processResult['changeEmail'] == true) {
        debugPrint(
          '📧 Usuario quiere cambiar email - mostrando pantalla de cambio',
        );
        _awaitingEmailChange = true; // Establecer flag
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "text": isSpanish
              ? "Por favor, ingresa tu nuevo correo electrónico:"
              : "Please enter your new email address:",
          "options": const <String>[],
          "step": "regProgress.emailChange",
          "keepTalk": false,
          "keyboardType": "email",
        };
      }

      // Manejar después de cambiar email: cuando usuario ingresa nuevo email en emailChange
      if (processResult != null && processResult['emailChanged'] == true) {
        debugPrint(
          '📧 Email cambiado exitosamente - volviendo a sendOTP para confirmar',
        );
        _awaitingEmailChange = false; // Limpiar flag

        // Si viene de cambio de email desde OTP, resetear índice a sendOTP
        if (_comingFromOTPEmailChange) {
          debugPrint(
            '📧 Volviendo desde cambio de email OTP - reseteando a sendOTP',
          );
          _currentQuestionIndex = questionFlow.indexOf('sendOTP');
          _comingFromOTPEmailChange = false; // Limpiar flag
        }

        // Retroceder a sendOTP para que confirme el nuevo email
        final emailQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          questionFlow.indexOf('sendOTP'),
          registerCubit,
        );

        if (emailQuestion != null) {
          return await _prepareQuestion(emailQuestion, registerCubit);
        }
      }

      // Manejar OTP enviado exitosamente
      if (processResult != null && processResult['otpSent'] == true) {
        debugPrint('📧 OTP enviado exitosamente');
        _awaitingEmailChange = false; // Limpiar flag si estaba activo
        // Continuar al siguiente paso (emailVerification)
      }

      // Manejar OTP reenviado
      if (processResult != null && processResult['otpResent'] == true) {
        debugPrint('📧 OTP reenviado exitosamente');
        // ignore: unused_local_variable
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "text": processResult['message'],
          "options": const <String>[],
          "step": "regProgress.emailVerification",
          "keepTalk": true,
        };
      }

      // Manejar cambio de email desde pantalla de OTP
      if (processResult != null &&
          processResult['changeEmailFromOTP'] == true) {
        debugPrint('📧 Usuario quiere cambiar email desde OTP');
        _awaitingEmailChange = true; // Establecer flag
        _comingFromOTPEmailChange = true; // Marcar que viene del OTP
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "text": isSpanish
              ? "Por favor, ingresa tu nuevo correo electrónico:"
              : "Please enter your new email address:",
          "options": const <String>[],
          "step": "regProgress.emailChange",
          "keepTalk": false,
          "keyboardType": "email",
        };
      }

      // Si no hubo errores, AHORA SÍ avanzar
      // IMPORTANTE: Si estamos en modo repetición, continuar con el flujo normal
      // desde el mismo step en el que el usuario estaba cuando pidió el cambio.
      // Nota: normalmente el usuario pide el cambio mientras ese step está pendiente,
      // por lo que NO debemos saltarlo (caso típico: último step de audio).
      if (_isInRepeatMode) {
        final resumeFrom = _previousQuestionIndex;
        debugPrint(
          '🔙 Saliendo de modo repetición - volviendo a índice $resumeFrom',
        );
        _currentQuestionIndex = resumeFrom;
        _isInRepeatMode = false;
      } else {
        _currentQuestionIndex++;
      }

      // Si el índice quedó fuera de rango, terminamos el flujo
      if (_currentQuestionIndex >= questionFlow.length) {
        debugPrint('🎉 Registro completado, no hay más preguntas.');
        return {
          "text": registerCubit.state.language == 'Español'
              ? "¡Listo! Ya terminamos tu registro 🎉"
              : "All set! Your registration is complete 🎉",
          "options": [],
          "step": "finished",
          "keepTalk": false,
        };
      }

      var nextQuestion = AssistantFunctions.getCurrentQuestion(
        questionFlow,
        _currentQuestionIndex,
        registerCubit,
      );

      // Manejo de keepTalk y posibles nulls devueltos por getCurrentQuestion
      while (nextQuestion == null || nextQuestion['keepTalk'] == true) {
        if (nextQuestion == null) {
          debugPrint(
            '⚠️ getCurrentQuestion devolvió null en índice $_currentQuestionIndex, finalizando flujo.',
          );
          return {
            "text": registerCubit.state.language == 'Español'
                ? "¡Listo! Ya terminamos tu registro 🎉"
                : "All set! Your registration is complete 🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        debugPrint(
          '⏩ Saltando mensaje keepTalk: ${questionFlow[_currentQuestionIndex]}',
        );

        _currentQuestionIndex++;
        if (_currentQuestionIndex >= questionFlow.length) {
          debugPrint('🎉 Registro completado durante skip keepTalk.');
          return {
            "text": registerCubit.state.language == 'Español'
                ? "¡Listo! Ya terminamos tu registro 🎉"
                : "All set! Your registration is complete 🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );
      }

      // Ahora nextQuestion es no-null y no tiene keepTalk == true
      return await _prepareQuestion(nextQuestion, registerCubit);
    }

    // SI NO ES VÁLIDO → MENSAJE DE ERROR
    if (decision['explainWhy'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      final fallback = isSpanish
          ? 'Con gusto. Te explico brevemente y continuamos.'
          : 'Sure. Let me explain briefly and continue.';

      var explain = _whyExplanation(currentStepKey, isSpanish);
      if (explain == null || explain.trim().isEmpty) {
        explain = fallback;
      }

      // Re-prompt específico para el paso de audio para que el usuario sepa qué hacer.
      final reprompt = currentStepKey == 'voiceNoteUrl'
          ? (isSpanish
              ? '\n\nPara continuar, graba tu nota de voz (1-10s) manteniendo presionado el micrófono, o escribe "Skip" para omitir.'
              : '\n\nTo continue, record your voice note (1-10s) by holding the microphone, or type "Skip" to skip.')
          : (isSpanish
              ? '\n\n¿Podrías responder la pregunta anterior, por favor?'
              : '\n\nNow, could you answer the previous question please?');

      return {
        "text": explain + reprompt,
        "options": const <String>[],
        "step": 'regProgress.$currentStepKey',
        "keepTalk": false,
        "repeatQuestion": true,
        "clearInput": true,
        "suggestions": const <Map<String, dynamic>>[],
      };
    }

    // MANEJO ESPECIAL: Si el usuario pide más sugerencias de usuario
    if (decision['requestMoreSuggestions'] == true &&
        currentStepKey == 'username') {
      final fullName = registerCubit.state.fullName ?? '';
      if (fullName.isNotEmpty) {
        final suggestions = AssistantFunctions.generateUsernameSuggestions(
          fullName,
        );
        if (suggestions.isNotEmpty) {
          debugPrint(
            '💡 [sendMessage] Generadas más sugerencias de usuario: $suggestions',
          );
          final isSpanish = registerCubit.state.language == 'Español';
          final message = isSpanish
              ? '¡Aquí hay más opciones! ¿Te gusta alguna de estas?'
              : 'Here are some more options! Do you like any of these?';
          return {
            "text": message,
            "options": <String>[],
            "suggestions": suggestions,
            "step": 'regProgress.username',
            "keepTalk": false,
          };
        }
      }
    }

    // MANEJO: Si el usuario hizo una pregunta sobre el campo actual o pregunta general
    // Detectar si la respuesta no es válida pero parece ser una pregunta
    final userInputText = decision['userResponse']?.toString().trim() ?? '';
    final isGeneralQuestion = _isGeneralQuestion(userInputText);

    // Solo tratamos como "pregunta" si realmente parece una pregunta.
    // Evita que respuestas típicas inválidas (p.ej. "No" en locationManual)
    // activen FieldGuidance y disparen repeatQuestion (lo que re-muestra Sí/No).
    final loweredInput = userInputText.toLowerCase().trim();
    final looksLikeQuestion =
        loweredInput.contains('?') ||
        loweredInput.contains('¿') ||
        RegExp(
          r'^(por\s*que|porqué|porque|para\s*que|paraqué|why|what|who|which|when|where|how|como|cómo|que|qué|quien|quién|cual|cuál|cuando|cuándo|donde|dónde)\b',
          caseSensitive: false,
        ).hasMatch(loweredInput);

    if (decision['valid'] == false && userInputText.isNotEmpty && looksLikeQuestion) {
      final isSpanish = registerCubit.state.language == 'Español';

      // Si estamos esperando ubicación manual, NO usar FieldGuidance/GeneralQ&A
      // porque eso devuelve repeatQuestion y re-muestra la pregunta de ubicación
      // (Sí/No), rompiendo el modo manual.
      if (_awaitingManualLocation && currentStepKey == 'locationManual') {
        final looksLikeWhy = RegExp(
          r'(\bwhy\b|por\s*que|porqué|porque|para\s*que|paraqué)',
          caseSensitive: false,
        ).hasMatch(loweredInput);

        if (looksLikeWhy) {
          final explanation = MigozzContext.getWhyExplanation(
            'location',
            isSpanish ? 'es' : 'en',
          );
          final manualReprompt = isSpanish
              ? "\n\nAhora escribe tu ubicación como:\nPaís, Ciudad, Estado/Departamento\nEj: Colombia, Medellín, Antioquia"
              : "\n\nNow type your location as:\nCountry, City, State/Region\nExample: Colombia, Medellin, Antioquia";

          return {
            "text": (explanation.isNotEmpty
                    ? explanation
                    : (isSpanish
                        ? 'Con gusto. Te explico y continuamos.'
                        : 'Sure. Let me explain and we continue.')) +
                manualReprompt,
            "options": const <String>[],
            "step": 'regProgress.location',
            "keepTalk": false,
            "clearInput": true,
            "suggestions": const <Map<String, dynamic>>[],
            "keyboardType": "text",
            "manualLocationPrompt": true,
          };
        }

        // Otra pregunta mientras estamos en modo manual: re-pedir formato manual
        return {
          "text": isSpanish
              ? "Entendido. Escribe tu ubicación como:\nPaís, Ciudad, Estado/Departamento\nEj: Colombia, Medellín, Antioquia"
              : "Got it. Type your location as:\nCountry, City, State/Region\nExample: Colombia, Medellin, Antioquia",
          "options": const <String>[],
          "step": 'regProgress.location',
          "keepTalk": false,
          "clearInput": true,
          "suggestions": const <Map<String, dynamic>>[],
          "keyboardType": "text",
          "manualLocationPrompt": true,
        };
      }

      // Primero: Si es pregunta sobre el CAMPO actual, devolver guía específica
      if (!isGeneralQuestion) {
        // Es pregunta sobre cómo llenar el campo actual
        debugPrint(
          '💡 [FieldGuidance] Usuario preguntó sobre el campo: $userInputText',
        );
        final guidance = _getFieldSpecificGuidance(currentStepKey, isSpanish);
        return {
          "text": guidance,
          "options": <String>[],
          "step": 'regProgress.$currentStepKey',
          "keepTalk": false,
          "repeatQuestion": true, // Volver a pedir respuesta del formulario
          "suggestions": [], // Limpiar sugerencias
          "clearInput": true, // Limpiar input para no entrar en loop
        };
      }

      // Segundo: Si es pregunta general, usar Gemini
      if (isGeneralQuestion) {
        debugPrint(
          '🤔 [GeneralQ&A] Usuario hizo pregunta general: $userInputText',
        );

        try {
          final response = await _model!.generateContent([
            Content.text(
              'Answer this question briefly in ${isSpanish ? 'Spanish' : 'English'} (max 2 sentences): $userInputText',
            ),
          ]);

          if (response.text != null && response.text!.isNotEmpty) {
            debugPrint('🤖 [GeneralQ&A] Respuesta Gemini: ${response.text}');
            return {
              "text": response.text,
              "options": <String>[],
              "step": 'regProgress.$currentStepKey',
              "keepTalk": false,
              "repeatQuestion": true,
              "suggestions": [],
              "clearInput": true, // Importante para evitar loop
            };
          }
        } catch (e, st) {
          debugPrint('❌ Error en GeneralQ&A: $e\n$st');
        }
      }
    }

    final err =
        AssistantFunctions.getErrorMessageForStep(
          currentStepKey,
          registerCubit,
        ) ??
        Map<String, dynamic>.from(decision);

    final enriched = await _enrichTextIfPossible(
      baseText: err['text']?.toString(),
      stepKey: currentStepKey,
      registerCubit: registerCubit,
      purpose: 'error',
    );
    if (enriched != null) err['text'] = enriched;

    if (err['text'] == null ||
        (err['text'] is String && (err['text'] as String).trim().isEmpty)) {
      final isSpanish = registerCubit.state.language == 'Español';
      err['text'] = isSpanish
          ? 'Por favor ingresa un valor válido.'
          : 'Please enter a valid value.';
      err['keepTalk'] = false;
    }

    // Limpiar opciones y sugerencias de error
    err['options'] = <String>[];
    err['suggestions'] = <Map<String, dynamic>>[];

    return err;
  }

  Future<Map<String, dynamic>> _prepareQuestion(
    Map<String, dynamic> question,
    RegisterCubit registerCubit,
  ) async {
    // SI estamos en el paso de ubicación, obtener la ubicación PRIMERO
    final currentStepKey = questionFlow[_currentQuestionIndex];
    if (currentStepKey == 'location') {
      final currentLocation = registerCubit.state.location;
      // Obtener ubicación si está vacía o null
      if (currentLocation == null || currentLocation.isEmpty) {
        debugPrint(
          '📍 [_prepareQuestion] Detectado paso de ubicación vacía o null - obteniendo ubicación...',
        );
        final language = registerCubit.state.language ?? _language;
        await registerCubit.fetchLocation(language);
        debugPrint(
          '📍 [_prepareQuestion] Ubicación obtenida: ${registerCubit.state.location?.city}',
        );
      }
    }

    // SI estamos en el paso de username, generar sugerencias dinámicas
    if (currentStepKey == 'username' &&
        question['generateSuggestions'] == true) {
      final fullName = registerCubit.state.fullName ?? '';
      if (fullName.isNotEmpty) {
        final suggestions = AssistantFunctions.generateUsernameSuggestions(
          fullName,
        );
        if (suggestions.isNotEmpty) {
          question['suggestions'] = suggestions;
          debugPrint(
            '💡 [_prepareQuestion] Generadas sugerencias de usuario: $suggestions',
          );
        }
      }
    }

    if (question['showProfilePictures'] == true) {
      final pictures = AssistantFunctions.getProfilePictures(registerCubit);
      if (pictures.isNotEmpty) {
        question['profilePictures'] = pictures;
      }
    }
    final rawOpts = question['options'];

    // Normalizar opciones a List<String> para el motor (usar label si viene como Map)
    final optionsForEnrichment = <String>[];
    if (rawOpts is List) {
      for (final o in rawOpts) {
        if (o == null) continue;
        if (o is String) {
          optionsForEnrichment.add(o);
        } else if (o is Map) {
          // Priorizar 'label' si existe, si no usar toString()
          final label = (o['label'] ?? o['text'])?.toString();
          if (label != null && label.isNotEmpty) {
            optionsForEnrichment.add(label);
          } else {
            optionsForEnrichment.add(o.toString());
          }
        } else {
          optionsForEnrichment.add(o.toString());
        }
      }
    }

    final enriched = await _enrichTextIfPossible(
      baseText: question['text']?.toString(),
      stepKey:
          question['step']?.toString() ?? questionFlow[_currentQuestionIndex],
      registerCubit: registerCubit,
      purpose: 'question',
      options: optionsForEnrichment,
    );
    if (enriched != null) {
      question['text'] = enriched;
    }
    return question;
  }

  Future<String?> _enrichTextIfPossible({
    required String? baseText,
    required String stepKey,
    required RegisterCubit registerCubit,
    required String purpose,
    List<String> options = const <String>[],
  }) async {
    ensureConfigured();
    if (_session == null) return null;

    final s = registerCubit.state;
    final known = _stateSummary(s);
    final intent = purpose == 'error'
        ? 'Write a very short, friendly correction and advice (<= 120 chars).'
        : 'Rephrase the prompt into a short, friendly question (<= 140 chars).';
    final opts = options.isNotEmpty
        ? 'Options: ${options.join(' | ')}'
        : 'Options: none';
    final seed = baseText == null || baseText.isEmpty
        ? 'Ask the user.'
        : baseText;

    final prompt = [
      'You are the registration assistant in a strict step-by-step wizard. Do NOT change the step order.',
      'Current step key: $stepKey',
      'Language: ${s.language ?? _language}',
      known,
      opts,
      'Seed text: "$seed"',
      intent,
      'Output: plain text only. No markdown, no emojis, no lists.',
    ].join('\n');

    try {
      final resp = await _session!
          .sendMessage(Content.text(prompt))
          .timeout(_enrichTimeout);
      final text = resp.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text.length > 180 ? text.substring(0, 180) : text;
    } on TimeoutException {
      if (kDebugMode) debugPrint('Gemini enrich timeout ($_enrichTimeout)');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini enrich error: $e');
      return null;
    }
  }

  String _stateSummary(dynamic s) {
    try {
      final parts = <String>[
        'Known values:',
        if (s.email != null) 'email=${s.email}',
        if (s.language != null) 'language=${s.language}',
        if (s.fullName != null) 'fullName=${s.fullName}',
        if (s.username != null) 'username=${s.username}',
        if (s.gender != null) 'gender=${s.gender}',
        if (s.location != null)
          'location=${s.location?.city}, ${s.location?.country}',
        if (s.phone != null) 'phoneSet=true',
        if (s.category != null) 'category=${s.category}',
        if (s.interests != null) 'interests=${s.interests?.keys.join(";")}',
        if (s.socialEcosystem != null)
          'socials=${s.socialEcosystem?.map((e) => e.keys.first).join(",")}',
      ];
      return parts.join(' | ');
    } catch (_) {
      return 'Known values: minimal';
    }
  }

  String? _whyExplanation(String stepKey, bool isSpanish) {
    // Use the comprehensive MigozzContext system
    final language = isSpanish ? 'es' : 'en';
    return MigozzContext.getShortExplanation(stepKey, language);
  }

  /// Detecta si el input es una pregunta GENERAL (no relacionada con el campo actual)
  /// Retorna false si parece pregunta sobre cómo llenar el campo
  /// Retorna true si es pregunta general no relacionada
  bool _isGeneralQuestion(String userInput) {
    if (userInput.isEmpty) return false;

    final lowered = userInput.toLowerCase().trim();

    // Primero: si parece pregunta sobre el CAMPO actual, NO es pregunta general
    // Patrones como "how should it be", "como deberia ser", "what format", etc.
    final fieldQuestionPatterns = [
      RegExp(
        r'(should|deberia|debería|puede|puedo|puedes|can|formato|format|'
        r'tipo|example|ejemplos|patron|pattern|rules|reglas|requirements|'
        r'characters|caracteres|permitido|allowed|que.*permitido|can.*use)',
      ),
      RegExp(
        r'(how|como|en que|que tipo)\s+(should|deberia|be|ser|es|escribo|write|format)',
      ),
    ];

    for (final pattern in fieldQuestionPatterns) {
      if (pattern.hasMatch(lowered)) {
        return false; // Es pregunta sobre el campo, NO es pregunta general
      }
    }

    // Segundo: patrones de NO preguntas (respuestas típicas)
    final responsePatterns = [
      RegExp(
        r'^(s[íi]|no|okay|ok|sure|yes|claro|dale|bueno|bien|vale|de acuerdo|exacto|correcto)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in responsePatterns) {
      if (pattern.hasMatch(lowered)) {
        return false;
      }
    }

    // Tercero: patrones de PREGUNTAS generales
    final generalQuestionPatterns = [
      RegExp(
        r'^(que|quién|cuál|cuándo|dónde|por qué|para qué|'
        r'what|who|which|when|where|why|how)\s',
        caseSensitive: false,
      ),
      RegExp(r'[?¿]$'),
    ];

    for (final pattern in generalQuestionPatterns) {
      if (pattern.hasMatch(lowered)) {
        return true;
      }
    }

    return false;
  }

  /// Genera contexto específico para responder preguntas sobre un campo
  String _getFieldSpecificGuidance(String fieldKey, bool isSpanish) {
    switch (fieldKey) {
      case 'username':
        return isSpanish
            ? '**Consejos para username:**\n'
                  '• Solo minúsculas (a-z)\n'
                  '• Sin espacios\n'
                  '• Puede incluir números (0-9)\n'
                  '• Caracteres permitidos: a-z, 0-9, _ (guion bajo), - (guion)\n'
                  '• NO permitidos: @, \$, !, espacios\n'
                  '• Mínimo 3 caracteres\n'
                  'Ejemplos: juan_arenilla, juanes2024, juan-ar'
            : '**Username Tips:**\n'
                  '• Lowercase only (a-z)\n'
                  '• No spaces\n'
                  '• Can include numbers (0-9)\n'
                  '• Allowed: a-z, 0-9, _ (underscore), - (dash)\n'
                  '• NOT allowed: @, \$, !, spaces\n'
                  '• Minimum 3 characters\n'
                  'Examples: juan_arenilla, juanes2024, juan-ar';
      case 'email':
        return isSpanish
            ? '**Email válido:**\n'
                  '• Formato: nombre@dominio.com\n'
                  '• Debe ser email real y activo\n'
                  '• Lo usaremos para verificar tu cuenta\n'
                  '• Asegúrate de que puedas acceder a él'
            : '**Valid Email:**\n'
                  '• Format: name@domain.com\n'
                  '• Must be a real, active email\n'
                  '• We\'ll use it to verify your account\n'
                  '• Make sure you have access to it';
      default:
        return isSpanish
            ? 'Ingresa un valor válido.'
            : 'Please enter a valid value.';
    }
  }
}
