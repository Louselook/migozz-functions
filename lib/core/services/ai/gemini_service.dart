import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:migozz_app/core/services/ai/assistant_functions.dart';
import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
import 'package:migozz_app/core/services/ai/migozz_context.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:permission_handler/permission_handler.dart';

class GeminiService {
  GeminiService._privateConstructor();
  static final GeminiService instance = GeminiService._privateConstructor();

  String _language = 'English';
  GenerativeModel? _model;
  ChatSession? _session;
  static const Duration _enrichTimeout = Duration(seconds: 8);
  String _modelName = 'gemini-2.5-flash';
  double _temperature = 0.4;
  int _maxOutputTokens = 180;
  bool _allowRuntimeSwitch = false;

  static const int _minOutputTokens = 120;
  static const int _maxOutputTokensCap = 1024;

  // Prompt enrichment is optional; disabling avoids any chance of truncated prompts.
  bool _enrichEnabled = false;

  // Track the config used for the currently created model/session.
  String? _configuredModelName;
  double? _configuredTemperature;
  int? _configuredMaxOutputTokens;

  bool _looksLikeAvatarHelpQuestion(String userInput) {
    final normalized = userInput
        .toLowerCase()
        .replaceAll(RegExp(r'[¿?¡!.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return false;

    // Very common user prompts at avatar step.
    if (normalized == 'como' || normalized == 'cómo' || normalized == 'como?') {
      return true;
    }
    if (normalized.startsWith('como subo') ||
        normalized.startsWith('cómo subo') ||
        normalized.contains('como subo una foto') ||
        normalized.contains('cómo subo una foto') ||
        normalized.contains('como subir una foto') ||
        normalized.contains('cómo subir una foto')) {
      return true;
    }
    return false;
  }

  String? _inferAvatarPlatformChoice(String userInput) {
    final normalized = userInput
        .toLowerCase()
        .replaceAll(RegExp(r'[¿?¡!.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return null;

    String canonical(String v) {
      final vv = v.replaceAll(' ', '').toLowerCase();
      if (vv == 'x') return 'twitter';
      if (vv == 'tiktok' || vv == 'tikt0k') return 'tiktok';
      if (vv == 'instagram' || vv == 'insta' || vv == 'ig') return 'instagram';
      if (vv == 'facebook' || vv == 'fb' || vv == 'face') return 'facebook';
      if (vv == 'youtube' || vv == 'yt' || vv == 'youtub') return 'youtube';
      if (vv == 'twitter') return 'twitter';
      if (vv == 'threads') return 'threads';
      if (vv == 'spotify' || vv == 'spoty') return 'spotify';
      if (vv == 'snapchat' || vv == 'snap') return 'snapchat';
      if (vv == 'linkedin' || vv == 'linkedIn') return 'linkedin';
      return vv;
    }

    // Lista de plataformas soportadas
    final platforms = [
      'instagram',
      'insta',
      'ig',
      'facebook',
      'fb',
      'face',
      'youtube',
      'yt',
      'tiktok',
      'tik tok',
      'twitter',
      'x',
      'threads',
      'spotify',
      'spoty',
      'snapchat',
      'snap',
      'linkedin',
    ];

    // Patrones en español: "la de instagram", "usa la de instagram", "quiero la de instagram"
    if (normalized.startsWith('la de ') || normalized.contains(' la de ')) {
      final match = RegExp(
        r'la de (?:mi |mis |tu )?(\w+)',
      ).firstMatch(normalized);
      if (match != null) {
        return canonical(match.group(1)!);
      }
    }

    // Patrones en inglés: "pick instagram", "use instagram", "the instagram one"
    // "pick the instagram one", "use the instagram photo", "instagram please"
    final pickPatterns = [
      RegExp(r'^pick\s+(?:the\s+)?(\w+)'),
      RegExp(r'^use\s+(?:the\s+)?(\w+)'),
      RegExp(r'^select\s+(?:the\s+)?(\w+)'),
      RegExp(r'^choose\s+(?:the\s+)?(\w+)'),
      RegExp(r'^the\s+(\w+)\s+(?:one|photo|picture|image)'),
      RegExp(r'^(\w+)\s+(?:one|photo|picture|image|please|por favor)$'),
      RegExp(r'^(?:i want |quiero |dame )(?:the\s+)?(\w+)'),
      RegExp(r'^(?:usar|usa|utilizar)\s+(?:la\s+de\s+)?(\w+)'),
      RegExp(r'^elegir\s+(?:la\s+de\s+)?(\w+)'),
      RegExp(r'^escoger\s+(?:la\s+de\s+)?(\w+)'),
    ];

    for (final pattern in pickPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final captured = match.group(1)?.toLowerCase() ?? '';
        // Verificar que es una plataforma válida
        for (final platform in platforms) {
          if (captured == platform ||
              captured.startsWith(
                platform.substring(
                  0,
                  platform.length > 3 ? 3 : platform.length,
                ),
              )) {
            return canonical(captured);
          }
        }
      }
    }

    // Detección directa: si el input es solo el nombre de la plataforma
    for (final platform in platforms) {
      if (normalized == platform) {
        return canonical(platform);
      }
    }

    // Búsqueda de plataforma en cualquier parte del texto corto (menos de 30 chars)
    if (normalized.length < 30) {
      for (final platform in platforms) {
        if (normalized.contains(platform)) {
          return canonical(platform);
        }
      }
    }

    return null;
  }

  String? _inferAvatarAction(String userInput) {
    final normalized = userInput
        .toLowerCase()
        .replaceAll(RegExp(r'[¿?¡!.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return null;

    // Camera intents
    final wantsCamera =
        normalized.contains('camara') ||
        normalized.contains('cámara') ||
        normalized.contains('con camara') ||
        normalized.contains('con cámara') ||
        normalized.contains('tomar foto') ||
        normalized.contains('tomar una foto') ||
        normalized.contains('sacar foto') ||
        normalized.contains('hacer una foto') ||
        normalized.contains('take a photo') ||
        normalized.contains('take photo') ||
        normalized.contains('open camera') ||
        normalized.contains('use camera');

    // Gallery intents
    final wantsGallery =
        normalized.contains('galeria') ||
        normalized.contains('galería') ||
        normalized.contains('foto de galeria') ||
        normalized.contains('foto de galería') ||
        normalized.contains('tomar foto desde galeria') ||
        normalized.contains('tomar foto desde galería') ||
        normalized.contains('subir una foto') ||
        normalized.contains('quiero subir una foto') ||
        normalized.contains('de la galeria') ||
        normalized.contains('de la galería') ||
        normalized.contains('elegir de la galeria') ||
        normalized.contains('elegir de la galería') ||
        normalized.contains('seleccionar de la galeria') ||
        normalized.contains('seleccionar de la galería') ||
        normalized.contains('choose from gallery') ||
        normalized.contains('from the gallery') ||
        normalized.contains('pick from gallery') ||
        normalized.contains('open gallery');

    if (wantsCamera && !wantsGallery) return 'open_camera';
    if (wantsGallery && !wantsCamera) return 'open_gallery';

    // If ambiguous, prefer not triggering an action.
    return null;
  }

  void ensureConfigured() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('GeminiService: GEMINI_API_KEY missing; AI text disabled.');
      }
      return;
    }
    try {
      // Always re-read env, and rebuild model/session if config changed.
      final envModel = dotenv.env['GEMINI_MODEL'];
      if (envModel != null && envModel.trim().isNotEmpty) {
        _modelName = envModel.trim();
      }

      final envEnrich = dotenv.env['GEMINI_ENRICH'];
      if (envEnrich != null) {
        final v = envEnrich.toLowerCase();
        _enrichEnabled = v == '1' || v == 'true' || v == 'yes';
      } else {
        _enrichEnabled = false;
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
        if (m != null) {
          // Very low token limits can truncate prompts mid-word (eg. "Ingresa tu nom").
          _maxOutputTokens = m.clamp(_minOutputTokens, _maxOutputTokensCap);
        }
      }

      // Enforce clamps even when env isn't set.
      _maxOutputTokens = _maxOutputTokens.clamp(
        _minOutputTokens,
        _maxOutputTokensCap,
      );

      final needsRebuild =
          _model == null ||
          _session == null ||
          _configuredModelName != _modelName ||
          _configuredTemperature != _temperature ||
          _configuredMaxOutputTokens != _maxOutputTokens;

      if (!needsRebuild) return;

      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: _temperature,
          maxOutputTokens: _maxOutputTokens,
        ),
      );
      _session = _model!.startChat();
      _configuredModelName = _modelName;
      _configuredTemperature = _temperature;
      _configuredMaxOutputTokens = _maxOutputTokens;
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
  bool _isInRepeatMode =
      false; // Flag para indicar que estamos en modo repetición
  bool _returnedFromRepeatMode =
      false; // Flag para indicar que volvimos del modo repetición (no incrementar índice)
  bool _awaitingEmailChange =
      false; // Flag para rastrear si estamos esperando cambio de email
  bool _comingFromOTPEmailChange =
      false; // Flag para saber si viene de cambio de email desde OTP
  bool _awaitingManualLocation =
      false; // Flag para rastrear si estamos esperando ubicación manual
  bool _awaitingConfirmation =
      false; // Flag para esperar confirmación después de cada campo
  bool _awaitingFieldSelection =
      false; // Flag para esperar selección de campo a cambiar
  bool _awaitingReservedUsernameConfirmation =
      false; // Flag para confirmación de username reservado (pre-registro)

  bool _requestedMicPermissionForVoiceStep = false;

  // Flujo completo para usuarios NO autenticados
  final List<String> _questionFlowNotAuth = [
    'fullName', // 1
    'username', // 2
    'location', // 3
    'sendOTP', // 4 - Confirmar email (ya disponible) y enviar código
    'emailVerification', // 5
    'otpInput', // 6
    'emailSuccess', // 7
    'socialEcosystem', // 8
    'avatarUrl', // 9
    'phone', // 10
    'voiceNoteUrl', // 11
    'category', // 12 - Seleccionar categorías
    'interests', // 13 - Seleccionar intereses
    'confirmCreateAccount', // 14
  ];

  //  Flujo reducido para usuarios autenticados
  final List<String> _questionFlowAuth = [
    'location',
    'phone',
    'socialEcosystem',
    'avatarUrl',
    'voiceNoteUrl',
    'category',
    'interests',
    'confirmCreateAccount',
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
    _returnedFromRepeatMode = false;
    _awaitingConfirmation = false;
    _awaitingFieldSelection = false;
    _awaitingReservedUsernameConfirmation = false;
  }

  /// Obtiene el valor guardado para mostrar en confirmación
  String? _getSavedValue(String fieldKey, RegisterCubit cubit) {
    final state = cubit.state;
    switch (fieldKey) {
      case 'fullName':
        return state.fullName;
      case 'username':
        return state.username;
      case 'location':
        final loc = state.location;
        if (loc != null && loc.hasCityAndCountry) {
          return '${loc.city}, ${loc.country}';
        }
        return null;
      case 'phone':
        return state.phone;
      case 'sendOTP':
        return state.email;
      default:
        return null;
    }
  }

  /// Genera mensaje de confirmación después de guardar un campo
  Map<String, dynamic> _buildConfirmationMessage(
    String fieldKey,
    RegisterCubit cubit,
  ) {
    final isSpanish = cubit.state.language == 'Español';
    final savedValue = _getSavedValue(fieldKey, cubit);

    String text;
    if (savedValue != null && savedValue.isNotEmpty) {
      text = isSpanish
          ? '✓ Listo: $savedValue\n¿Seguimos con el siguiente paso?'
          : '✓ Got it: $savedValue\nShall we continue?';
    } else {
      text = isSpanish
          ? '✓ Guardado.\n¿Seguimos con el siguiente paso?'
          : '✓ Saved.\nShall we continue?';
    }

    return {
      "text": text,
      "options": isSpanish
          ? ["Sí, continuar", "Quiero cambiar algo"]
          : ["Yes, continue", "I want to change something"],
      "step": "regProgress.confirmation",
      "keepTalk": false,
      "awaitingConfirmation": true,
      "lastField": fieldKey,
    };
  }

  /// Lista de campos que requieren confirmación (no pasos intermedios como OTP)
  bool _shouldConfirmField(String fieldKey) {
    // Campos que sí requieren confirmación explícita
    const confirmableFields = ['fullName', 'username', 'phone'];
    return confirmableFields.contains(fieldKey);
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
    if (maxTokens != null) {
      _maxOutputTokens = maxTokens.clamp(_minOutputTokens, _maxOutputTokensCap);
    }

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

    // ✅ MANEJO DE CONFIRMACIÓN DE USERNAME RESERVADO (pre-registro)
    if (_awaitingReservedUsernameConfirmation && userInput.trim().isNotEmpty) {
      final normalized = userInput.trim().toLowerCase();
      final isSpanish = registerCubit.state.language == 'Español';

      // Usuario confirma el username reservado
      final confirmsUsername =
          normalized == 'sí' ||
          normalized == 'si' ||
          normalized == 'yes' ||
          normalized == 'ok' ||
          normalized == 'correcto' ||
          normalized == 'correct';

      // Usuario quiere cambiar el username
      final wantsChange =
          normalized == 'no' ||
          normalized == 'cambiar' ||
          normalized == 'change' ||
          normalized.contains('quiero otro') ||
          normalized.contains('want another');

      if (confirmsUsername) {
        debugPrint('✅ Usuario confirmó username reservado');
        _awaitingReservedUsernameConfirmation = false;

        // Avanzar al siguiente paso (location)
        _currentQuestionIndex++;

        if (_currentQuestionIndex >= questionFlow.length) {
          return {
            "text": isSpanish
                ? "✅ Registro completado."
                : "✅ Registration complete.",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion != null) {
          return await _prepareQuestion(nextQuestion, registerCubit);
        }
      }

      if (wantsChange) {
        debugPrint('🔄 Usuario quiere cambiar username reservado');
        _awaitingReservedUsernameConfirmation = false;

        // Permitir que ingrese un nuevo username
        return {
          "text": isSpanish
              ? "Entendido. Escribe el nombre de usuario que prefieras:"
              : "Got it. Enter the username you prefer:",
          "options": const <String>[],
          "step": "regProgress.username",
          "keepTalk": false,
        };
      }

      // Si no reconocemos la respuesta, repetir la pregunta
      final reservedUsername = registerCubit.state.username ?? '';
      return {
        "text": isSpanish
            ? "Tu nombre de usuario reservado es @$reservedUsername. ¿Es correcto?"
            : "Your reserved username is @$reservedUsername. Is this correct?",
        "options": [isSpanish ? "Sí" : "Yes", isSpanish ? "No" : "No"],
        "step": "username",
        "keepTalk": false,
      };
    }

    // ✅ MANEJO DE SELECCIÓN DE CAMPO: Si estamos esperando que el usuario elija qué cambiar
    if (_awaitingFieldSelection && userInput.trim().isNotEmpty) {
      final normalized = userInput.trim().toLowerCase();
      final isSpanish = registerCubit.state.language == 'Español';

      final wantsChangeName =
          normalized == 'nombre' ||
          normalized == 'name' ||
          normalized == 'mi nombre' ||
          normalized == 'my name' ||
          normalized == 'nombre completo' ||
          normalized == 'full name';

      final wantsChangeUsername =
          normalized == 'usuario' ||
          normalized == 'username' ||
          normalized == 'mi usuario' ||
          normalized == 'my username';

      final wantsChangePhone =
          normalized == 'teléfono' ||
          normalized == 'telefono' ||
          normalized == 'phone' ||
          normalized == 'mi teléfono' ||
          normalized == 'my phone';

      final wantsChangeEmail =
          normalized == 'correo' ||
          normalized == 'email' ||
          normalized == 'mi correo' ||
          normalized == 'my email';

      final wantsChangeCategory =
          normalized.contains('categoría') ||
          normalized.contains('categoria') ||
          normalized.contains('category') ||
          normalized == 'mi categoría' ||
          normalized == 'my category';

      final wantsChangeInterests =
          normalized.contains('interés') ||
          normalized.contains('interes') ||
          normalized.contains('interests') ||
          normalized.contains('interest') ||
          normalized == 'mis intereses' ||
          normalized == 'my interests';

      final wantsNothingContinue =
          normalized.contains('nada') ||
          normalized.contains('nothing') ||
          normalized.contains('nada, continuar') ||
          normalized.contains('nothing, continue');

      if (wantsNothingContinue) {
        _awaitingFieldSelection = false;

        // Si estamos en socialEcosystem y no hay redes, NO AVANZAR - son obligatorias
        final currentStep = questionFlow[_currentQuestionIndex];
        final hasNetworks =
            (registerCubit.state.socialEcosystem?.isNotEmpty ?? false);

        if (currentStep == 'socialEcosystem' && !hasNetworks) {
          debugPrint(
            '⚠️ [wantsNothingContinue] En socialEcosystem sin redes - OBLIGATORIO vincular',
          );
          return {
            "text": isSpanish
                ? "Para continuar debes vincular al menos una red social. Es un requisito obligatorio para tu perfil. 📱"
                : "To continue you must link at least one social network. It's a mandatory requirement for your profile. 📱",
            "options": isSpanish ? ["Vincular redes"] : ["Link networks"],
            "step": "regProgress.socialEcosystem",
            "keepTalk": false,
            "action": 0, // Abrir pantalla de redes sociales
          };
        }

        // Usuario decidió no cambiar nada, continuar
        _currentQuestionIndex++;
        if (_currentQuestionIndex >= questionFlow.length) {
          return {
            "text": isSpanish
                ? "✅ Registro completado."
                : "✅ Registration complete.",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }
        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );
        if (nextQuestion != null) {
          return await _prepareQuestion(nextQuestion, registerCubit);
        }
      }

      if (wantsChangeName ||
          wantsChangeUsername ||
          wantsChangePhone ||
          wantsChangeEmail ||
          wantsChangeCategory ||
          wantsChangeInterests) {
        _awaitingFieldSelection = false;
        _returnedFromRepeatMode =
            false; // Limpiar flag - vamos a entrar en un nuevo repeat mode
        String targetField;
        String promptText;

        if (wantsChangeName) {
          targetField = 'fullName';
          promptText = isSpanish
              ? "Escribe tu nombre completo:"
              : "Enter your full name:";
        } else if (wantsChangeUsername) {
          targetField = 'username';
          promptText = isSpanish
              ? "Escribe el nombre de usuario que quieres usar:"
              : "Enter the username you want to use:";
        } else if (wantsChangeEmail) {
          // Para cambiar email, reiniciamos el OTP
          targetField = 'sendOTP';
          promptText = isSpanish
              ? "Escribe tu nuevo correo electrónico:"
              : "Enter your new email:";
          // Limpiar el OTP anterior
          registerCubit.setCurrentOTP('');
        } else if (wantsChangePhone) {
          targetField = 'phone';
          promptText = isSpanish
              ? "Escribe tu número de teléfono:"
              : "Enter your phone number:";
        } else if (wantsChangeCategory) {
          targetField = 'category';
          promptText = isSpanish
              ? "Perfecto, vamos a actualizar tu categoría. ¿Cuál es tu especialidad principal?"
              : "Perfect, let's update your category. What's your main specialty?";
        } else {
          // wantsChangeInterests
          targetField = 'interests';
          promptText = isSpanish
              ? "Excelente, vamos a actualizar tus intereses. ¿Cuáles son tus temas de interés?"
              : "Great, let's update your interests. What are your topics of interest?";
        }

        // Entrar en modo repetición para ese campo
        final fieldIndex = questionFlow.indexOf(targetField);
        if (fieldIndex >= 0) {
          _previousQuestionIndex = _currentQuestionIndex;
          _isInRepeatMode = true;
          _currentQuestionIndex = fieldIndex;

          // Para category e interests, mostrar las opciones UI nativas
          if (targetField == 'category' || targetField == 'interests') {
            final actionCode = targetField == 'category' ? 1 : 2;
            return {
              "text": promptText,
              "options": [],
              "step": "regProgress.$targetField",
              "keepTalk": false,
              "action": actionCode, // 1 para category, 2 para interests
            };
          }

          return {
            "text": promptText,
            "options": [],
            "step": "regProgress.$targetField",
            "keepTalk": false,
            "keyboardType": targetField == 'phone' ? "number" : "text",
          };
        }
      }

      // Si no reconocemos la respuesta, repetir las opciones con resumen
      final fullName = registerCubit.state.fullName ?? '';
      final username = registerCubit.state.username ?? '';
      final email = registerCubit.state.email ?? '';

      final summary = isSpanish
          ? "📋 Tus datos actuales:\n• Nombre: $fullName\n• Usuario: @$username\n• Correo: $email\n\n¿Cuál quieres cambiar?"
          : "📋 Your current data:\n• Name: $fullName\n• Username: @$username\n• Email: $email\n\nWhich one do you want to change?";

      return {
        "text": summary,
        "options": isSpanish
            ? ["Nombre", "Username", "Correo", "Categoría", "Intereses", "Nada, continuar"]
            : ["Name", "Username", "Email", "Category", "Interests", "Nothing, continue"],
        "step": "regProgress.changeRequest",
        "keepTalk": false,
      };
    }

    // ✅ MANEJO DE CONFIRMACIÓN: Si estamos esperando respuesta de confirmación
    if (_awaitingConfirmation && userInput.trim().isNotEmpty) {
      final normalized = userInput.trim().toLowerCase();
      final isSpanish = registerCubit.state.language == 'Español';

      // Usuario quiere continuar
      final wantsContinue =
          normalized == 'continuar' ||
          normalized == 'continue' ||
          normalized == 'si' ||
          normalized == 'sí' ||
          normalized == 'yes' ||
          normalized == 'ok' ||
          normalized == 'okay' ||
          normalized == 'dale' ||
          normalized == 'siguiente' ||
          normalized == 'next' ||
          normalized.contains('sí, continuar') ||
          normalized.contains('si, continuar') ||
          normalized.contains('yes, continue');

      if (wantsContinue) {
        debugPrint('✅ Usuario confirmó continuar');
        _awaitingConfirmation = false;

        // Si volvimos del modo repetición, NO incrementar (ya estamos en el índice correcto)
        if (_returnedFromRepeatMode) {
          debugPrint(
            '🔙 Volvimos del modo repetición - mostrando paso actual: ${questionFlow[_currentQuestionIndex]}',
          );
          _returnedFromRepeatMode = false; // Limpiar flag
        } else {
          // Avanzar al siguiente paso solo si no venimos del modo repetición
          _currentQuestionIndex++;
        }

        if (_currentQuestionIndex >= questionFlow.length) {
          return {
            "text": isSpanish
                ? "✅ Registro completado."
                : "✅ Registration complete.",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion == null) {
          return {
            "text": isSpanish
                ? "✅ Registro completado."
                : "✅ Registration complete.",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        return await _prepareQuestion(nextQuestion, registerCubit);
      }

      // Usuario quiere cambiar algo
      final wantsChange =
          normalized == 'cambiar' ||
          normalized == 'change' ||
          normalized.contains('cambiar') ||
          normalized.contains('change') ||
          normalized.contains('editar') ||
          normalized.contains('edit') ||
          normalized.contains('modificar') ||
          normalized.contains('corregir') ||
          normalized.contains('quiero cambiar');

      if (wantsChange) {
        debugPrint('🔄 Usuario quiere cambiar algo de su registro');
        _awaitingConfirmation = false;
        _awaitingFieldSelection = true; // Esperando selección de campo
        _returnedFromRepeatMode =
            false; // Limpiar flag - ya no estamos volviendo de repeat mode

        // Obtener datos actuales para mostrar resumen
        final fullName = registerCubit.state.fullName ?? '';
        final username = registerCubit.state.username ?? '';
        final email = registerCubit.state.email ?? '';

        final summary = isSpanish
            ? "📋 Tus datos actuales:\n• Nombre: $fullName\n• Usuario: @$username\n• Correo: $email\n\n¿Cuál quieres cambiar?"
            : "📋 Your current data:\n• Name: $fullName\n• Username: @$username\n• Email: $email\n\nWhich one do you want to change?";

        // Mostrar opciones de qué campo quiere cambiar
        return {
          "text": summary,
          "options": isSpanish
              ? ["Nombre", "Username", "Correo", "Nada, continuar"]
              : ["Name", "Username", "Email", "Nothing, continue"],
          "step": "regProgress.changeRequest",
          "keepTalk": false,
          "changeRequest": true,
        };
      }

      // Si no reconocemos la respuesta, repetir las opciones
      return {
        "text": isSpanish
            ? "¿Continuamos o quieres cambiar algo?"
            : "Shall we continue or change something?",
        "options": isSpanish
            ? ["Sí, continuar", "Quiero cambiar algo"]
            : ["Yes, continue", "I want to change something"],
        "step": "regProgress.confirmation",
        "keepTalk": false,
        "awaitingConfirmation": true,
      };
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
              ? "¡ Registro completado.🎉"
              : " Registration complete.🎉",
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

    // ✅ Manejo especial para socialEcosystem: detectar retorno con redes vinculadas
    // Cuando el usuario regresa de vincular redes, el mensaje interno es 'socials_updated'
    if (currentStepKey == 'socialEcosystem') {
      final normalized = userInput.trim().toLowerCase();

      // Detectar mensaje interno de sistema (indica que las redes fueron actualizadas)
      if (normalized == 'socials_updated' ||
          normalized == 'done' ||
          normalized == 'continue') {
        final hasNetworks =
            (registerCubit.state.socialEcosystem?.isNotEmpty ?? false);
        final isSpanish = registerCubit.state.language == 'Español';

        if (hasNetworks) {
          // Redes vinculadas exitosamente - avanzar al siguiente paso
          debugPrint(
            '✅ [socialEcosystem] Redes vinculadas, avanzando al siguiente paso',
          );

          // Salir del modo repetición si estábamos en él
          if (_isInRepeatMode) {
            _currentQuestionIndex = _previousQuestionIndex;
            _isInRepeatMode = false;
            debugPrint('🔙 Saliendo de modo repetición desde socialEcosystem');
          } else {
            _currentQuestionIndex++;
          }

          // Obtener siguiente pregunta
          if (_currentQuestionIndex >= questionFlow.length) {
            return {
              "text": isSpanish
                  ? "¡ Registro completado.🎉"
                  : " Registration complete.🎉",
              "options": [],
              "step": "finished",
              "keepTalk": false,
            };
          }

          final nextQuestion = AssistantFunctions.getCurrentQuestion(
            questionFlow,
            _currentQuestionIndex,
            registerCubit,
          );

          if (nextQuestion == null) {
            return {
              "text": isSpanish
                  ? "¡ Registro completado.🎉"
                  : " Registration complete.🎉",
              "options": [],
              "step": "finished",
              "keepTalk": false,
            };
          }

          return await _prepareQuestion(nextQuestion, registerCubit);
        } else {
          // No hay redes vinculadas - preguntar si quiere continuar sin redes
          return {
            "text": isSpanish
                ? "No vinculaste ninguna red social. ¿Deseas continuar sin vincular redes?"
                : "You didn't link any social networks. Do you want to continue without linking networks?",
            "options": isSpanish
                ? ["Sí, continuar", "Vincular redes"]
                : ["Yes, continue", "Link networks"],
            "step": "regProgress.socialEcosystem",
            "keepTalk": false,
          };
        }
      }

      // Manejar cuando el usuario vuelve sin redes y se le preguntó si quiere cambiar datos
      if (normalized == 'awaiting_change_decision') {
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "text": isSpanish
              ? "¿Quieres cambiar algún dato antes de continuar?"
              : "Do you want to change any information before continuing?",
          "options": isSpanish
              ? ["No, continuar", "Sí, cambiar datos"]
              : ["No, continue", "Yes, change data"],
          "step": "regProgress.socialEcosystem",
          "keepTalk": false,
          "awaitingChangeDecision": true,
        };
      }

      // Si el usuario dice "Sí, cambiar datos" - mostrar opciones de campos
      if (normalized.contains('cambiar datos') ||
          normalized.contains('change data') ||
          normalized.contains('sí, cambiar') ||
          normalized.contains('yes, change')) {
        final isSpanish = registerCubit.state.language == 'Español';
        debugPrint('🔄 [socialEcosystem] Usuario quiere cambiar datos');
        _awaitingFieldSelection = true;

        // Obtener datos actuales para mostrar resumen
        final fullName = registerCubit.state.fullName ?? '';
        final username = registerCubit.state.username ?? '';
        final email = registerCubit.state.email ?? '';

        final summary = isSpanish
            ? "📋 Tus datos actuales:\n• Nombre: $fullName\n• Usuario: @$username\n• Correo: $email\n\n¿Cuál quieres cambiar?"
            : "📋 Your current data:\n• Name: $fullName\n• Username: @$username\n• Email: $email\n\nWhich one do you want to change?";

        return {
          "text": summary,
          "options": isSpanish
              ? ["Nombre", "Username", "Correo", "Nada, continuar"]
              : ["Name", "Username", "Email", "Nothing, continue"],
          "step": "regProgress.socialEcosystem",
          "keepTalk": false,
        };
      }

      // Si el usuario dice "No, continuar" (sin redes) - las redes son OBLIGATORIAS
      if ((normalized.contains('no, continuar') ||
              normalized.contains('no, continue') ||
              (normalized == 'no' &&
                  !(registerCubit.state.socialEcosystem?.isNotEmpty ??
                      false))) &&
          !(registerCubit.state.socialEcosystem?.isNotEmpty ?? false)) {
        final isSpanish = registerCubit.state.language == 'Español';
        debugPrint(
          '⚠️ [socialEcosystem] Usuario quiere continuar sin redes - OBLIGATORIO vincular',
        );
        return {
          "text": isSpanish
              ? "Para continuar debes vincular al menos una red social. Es un requisito obligatorio para tu perfil. 📱"
              : "To continue you must link at least one social network. It's a mandatory requirement for your profile. 📱",
          "options": isSpanish ? ["Vincular redes"] : ["Link networks"],
          "step": "regProgress.socialEcosystem",
          "keepTalk": false,
          "action": 0, // Abrir pantalla de redes sociales
        };
      }

      // Si el usuario quiere vincular redes - abrir la pantalla
      if (normalized.contains('vincular') ||
          normalized.contains('link') ||
          normalized.contains('agregar') ||
          normalized.contains('add')) {
        final isSpanish = registerCubit.state.language == 'Español';
        debugPrint('🔗 [socialEcosystem] Usuario quiere vincular redes');
        return {
          "text": isSpanish
              ? "Vamos a vincular tus redes sociales. 📱"
              : "Let's link your social networks. 📱",
          "options": [],
          "step": "regProgress.socialEcosystem",
          "keepTalk": false,
          "action": 0, // Abrir pantalla de redes sociales
        };
      }

      // Si el usuario dice que sí quiere continuar sin redes (legacy - pero ahora obligatorio)
      if (normalized.contains('continuar') ||
          normalized.contains('continue') ||
          normalized == 'si' ||
          normalized == 'sí' ||
          normalized == 'yes') {
        // Verificar si tiene redes
        if (registerCubit.state.socialEcosystem?.isNotEmpty ?? false) {
          debugPrint('✅ [socialEcosystem] Usuario continúa con redes');

          if (_isInRepeatMode) {
            _currentQuestionIndex = _previousQuestionIndex;
            _isInRepeatMode = false;
          } else {
            _currentQuestionIndex++;
          }

          if (_currentQuestionIndex >= questionFlow.length) {
            final isSpanish = registerCubit.state.language == 'Español';
            return {
              "text": isSpanish
                  ? "¡ Registro completado.🎉"
                  : " Registration complete.🎉",
              "options": [],
              "step": "finished",
              "keepTalk": false,
            };
          }

          final nextQuestion = AssistantFunctions.getCurrentQuestion(
            questionFlow,
            _currentQuestionIndex,
            registerCubit,
          );

          if (nextQuestion != null) {
            return await _prepareQuestion(nextQuestion, registerCubit);
          }
        } else {
          // No tiene redes - obligatorio vincular
          final isSpanish = registerCubit.state.language == 'Español';
          debugPrint(
            '⚠️ [socialEcosystem] Intento de continuar sin redes - OBLIGATORIO',
          );
          return {
            "text": isSpanish
                ? "Para continuar debes vincular al menos una red social. Es un requisito obligatorio para tu perfil. 📱"
                : "To continue you must link at least one social network. It's a mandatory requirement for your profile. 📱",
            "options": isSpanish ? ["Vincular redes"] : ["Link networks"],
            "step": "regProgress.socialEcosystem",
            "keepTalk": false,
            "action": 0,
          };
        }
      }
    }

    // ✅ Manejo especial para category: detectar retorno después de seleccionar categorías
    if (currentStepKey == 'category') {
      final normalized = userInput.trim().toLowerCase();

      if (normalized == 'category_updated' ||
          normalized == 'done' ||
          normalized == 'continue') {
        final isSpanish = registerCubit.state.language == 'Español';

        debugPrint(
          '✅ [category] Categorías seleccionadas, avanzando al siguiente paso',
        );

        // Salir del modo repetición si estábamos en él
        if (_isInRepeatMode) {
          _currentQuestionIndex = _previousQuestionIndex;
          _isInRepeatMode = false;
          debugPrint('🔙 Saliendo de modo repetición desde category');
        } else {
          _currentQuestionIndex++;
        }

        // Obtener siguiente pregunta
        if (_currentQuestionIndex >= questionFlow.length) {
          return {
            "text": isSpanish
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion == null) {
          return {
            "text": isSpanish
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        return await _prepareQuestion(nextQuestion, registerCubit);
      }
    }

    // ✅ Manejo especial para interests: detectar retorno después de seleccionar intereses
    if (currentStepKey == 'interests') {
      final normalized = userInput.trim().toLowerCase();

      if (normalized == 'interests_updated' ||
          normalized == 'done' ||
          normalized == 'continue') {
        final isSpanish = registerCubit.state.language == 'Español';

        debugPrint(
          '✅ [interests] Intereses seleccionados, avanzando al siguiente paso',
        );

        // Salir del modo repetición si estábamos en él
        if (_isInRepeatMode) {
          _currentQuestionIndex = _previousQuestionIndex;
          _isInRepeatMode = false;
          debugPrint('🔙 Saliendo de modo repetición desde interests');
        } else {
          _currentQuestionIndex++;
        }

        // Obtener siguiente pregunta
        if (_currentQuestionIndex >= questionFlow.length) {
          return {
            "text": isSpanish
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion == null) {
          return {
            "text": isSpanish
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        return await _prepareQuestion(nextQuestion, registerCubit);
      }
    }

    // ✅ Extra context for avatar step: convert free-text intents to explicit actions.
    // This keeps the user on the same step (no index advance) and lets the UI
    // open camera/gallery even if the user typed instead of tapping buttons.
    if (currentStepKey == 'avatarUrl' && !kIsWeb) {
      // 1) Help / how-to questions
      if (_looksLikeAvatarHelpQuestion(userInput)) {
        final isSpanish = registerCubit.state.language == 'Español';
        final helpText = isSpanish
            ? 'Para subir tu foto puedes:\n\n1) Escribir "Tomar foto" (o "Quiero tomar una foto") para abrir la cámara\n2) Escribir "Galería" (o "Quiero subir una foto") para elegir desde tu galería\n3) Si ya sincronizaste redes, puedes escribir "la de instagram" / "la de tiktok" para usar esa foto.'
            : 'To add your photo you can:\n\n1) Type "Take photo" (or "I want to take a photo") to open the camera\n2) Type "Gallery" (or "I want to upload a photo") to pick from your gallery\n3) If you synced socials, you can type "the Instagram one" / "the TikTok one" to use that profile photo.';

        return {
          'text': helpText,
          'options': const <String>[],
          'step': 'regProgress.avatarUrl',
          'keepTalk': false,
          'repeatQuestion': true,
          'clearInput': true,
        };
      }

      // 2) "la de {red social}" → choose from synced profile pictures
      final platform = _inferAvatarPlatformChoice(userInput);
      if (platform != null) {
        final pictures = AssistantFunctions.getProfilePictures(registerCubit);
        final match = pictures.firstWhere(
          (p) => (p['platform'] ?? '').toLowerCase() == platform,
          orElse: () => const <String, String>{},
        );

        final imageUrl = match['imageUrl'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final isSpanish = registerCubit.state.language == 'Español';
          final msg = isSpanish
              ? 'Perfecto — usaré tu foto de $platform.'
              : 'Perfect — I’ll use your $platform photo.';
          return {
            'text': msg,
            'options': const <String>[],
            'step': 'regProgress.avatarUrl',
            'valid': true,
            'keepTalk': false,
            'action': 'use_profile_picture',
            'imageUrl': imageUrl,
            'userResponse': imageUrl,
            'clearInput': true,
          };
        }

        final isSpanish = registerCubit.state.language == 'Español';
        final available = pictures
            .map((p) => (p['platform'] ?? '').toLowerCase())
            .where((p) => p.isNotEmpty)
            .toSet()
            .toList();
        final availText = available.isEmpty
            ? ''
            : (isSpanish
                  ? '\n\nTengo fotos disponibles de: ${available.join(', ')}'
                  : '\n\nI have photos available from: ${available.join(', ')}');

        return {
          'text':
              (isSpanish
                  ? 'No encontré una foto para "$platform". Puedes elegir cámara/galería o usar otra red.'
                  : 'I couldn’t find a photo for "$platform". You can pick camera/gallery or choose another social.') +
              availText,
          'options': const <String>[],
          'step': 'regProgress.avatarUrl',
          'keepTalk': false,
          'repeatQuestion': true,
          'clearInput': true,
        };
      }

      // 3) camera/gallery actions
      final action = _inferAvatarAction(userInput);
      if (action != null) {
        final isSpanish = registerCubit.state.language == 'Español';
        final text = action == 'open_camera'
            ? (isSpanish
                  ? 'Perfecto — abriendo la cámara.'
                  : 'Perfect — opening the camera.')
            : (isSpanish
                  ? 'Perfecto — abriendo tu galería.'
                  : 'Perfect — opening your gallery.');

        return {
          "text": text,
          "options": const <String>[],
          "step": 'regProgress.avatarUrl',
          "keepTalk": false,
          "action": action,
          "clearInput": true,
        };
      }
    }

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
        final blockMessage =
            decision['message'] as String? ??
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
      final blockMessage =
          decision['message'] as String? ??
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
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
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

        // Avanzar al paso de emailVerification para que el siguiente input sea procesado correctamente
        _currentQuestionIndex = questionFlow.indexOf('emailVerification');
        debugPrint(
          '📧 Avanzando a emailVerification, índice: $_currentQuestionIndex',
        );

        // Mostrar mensaje de confirmación de envío de OTP
        final isSpanish = registerCubit.state.language == 'Español';
        final userEmail = registerCubit.state.email ?? '';
        return {
          "text": isSpanish
              ? "📩 Se ha enviado un código de 6 dígitos a tu correo: $userEmail"
              : "📩 A 6-digit code has been sent to your email: $userEmail",
          "options": isSpanish
              ? ["Reenviar código", "Cambiar correo"]
              : ["Resend code", "Change email"],
          "step": "regProgress.emailVerification",
          "keepTalk": false,
          "keyboardType": "number",
        };
      }

      // Manejar OTP reenviado
      if (processResult != null && processResult['otpResent'] == true) {
        debugPrint('📧 OTP reenviado exitosamente');
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "text": processResult['message'],
          "options": isSpanish
              ? ["Reenviar código", "Cambiar correo"]
              : ["Resend code", "Change email"],
          "step": "regProgress.emailVerification",
          "keepTalk": false,
          "keyboardType": "number",
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

      // Manejar email verificado correctamente
      if (processResult != null && processResult['verified'] == true) {
        debugPrint('✅ Email verificado - avanzando al siguiente paso');

        // Saltar los pasos de otpInput y emailSuccess, ir directamente a socialEcosystem
        final socialIndex = questionFlow.indexOf('socialEcosystem');
        if (socialIndex != -1) {
          _currentQuestionIndex = socialIndex;
        } else {
          // Fallback: saltar los pasos de transición
          _currentQuestionIndex = questionFlow.indexOf('emailVerification') + 3;
        }
        debugPrint(
          '📧 Email verificado - saltando a socialEcosystem, nuevo índice: $_currentQuestionIndex',
        );

        // Mostrar la siguiente pregunta (socialEcosystem)
        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion != null) {
          return await _prepareQuestion(nextQuestion, registerCubit);
        }
      }

      // Si no hubo errores, AHORA SÍ avanzar
      // IMPORTANTE: Si estamos en modo repetición, continuar con el flujo normal
      // desde el mismo step en el que el usuario estaba cuando pidió el cambio.
      // Nota: normalmente el usuario pide el cambio mientras ese step está pendiente,
      // por lo que NO debemos saltarlo (caso típico: último step de audio).

      // ✅ CONFIRMACIÓN: Si el campo requiere confirmación, mostrarla antes de avanzar
      final savedFieldKey = currentStepKey;
      if (_shouldConfirmField(savedFieldKey)) {
        debugPrint('📋 Mostrando confirmación para campo: $savedFieldKey');
        _awaitingConfirmation = true;

        // Si estamos en modo repetición, salir de él antes de mostrar confirmación
        if (_isInRepeatMode) {
          _currentQuestionIndex = _previousQuestionIndex;
          _isInRepeatMode = false;
          _returnedFromRepeatMode =
              true; // Marcar que volvimos del modo repetición
          debugPrint(
            '🔙 Volvimos del modo repetición - índice: $_currentQuestionIndex (NO incrementar después)',
          );
        }

        return _buildConfirmationMessage(savedFieldKey, registerCubit);
      }

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
              ? "¡ Registro completado.🎉"
              : " Registration complete.🎉",
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
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
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
                ? "¡ Registro completado.🎉"
                : " Registration complete.🎉",
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

    if (decision['valid'] == false &&
        userInputText.isNotEmpty &&
        looksLikeQuestion) {
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
            "text":
                (explanation.isNotEmpty
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

    if (_enrichEnabled) {
      final enriched = await _enrichTextIfPossible(
        baseText: err['text']?.toString(),
        stepKey: currentStepKey,
        registerCubit: registerCubit,
        purpose: 'error',
      );
      if (enriched != null) err['text'] = enriched;
    }

    if (err['text'] == null ||
        (err['text'] is String && (err['text'] as String).trim().isEmpty)) {
      final isSpanish = registerCubit.state.language == 'Español';
      err['text'] = isSpanish
          ? 'Por favor ingresa un valor válido.'
          : 'Please enter a valid value.';
      err['keepTalk'] = false;
    }

    // Para el paso de emailVerification, siempre mostrar las opciones de reenviar/cambiar
    if (currentStepKey == 'emailVerification') {
      final isSpanish = registerCubit.state.language == 'Español';
      err['options'] = isSpanish
          ? ["Reenviar código", "Cambiar correo"]
          : ["Resend code", "Change email"];
      err['keyboardType'] = 'number';
      // Usar mensaje de error específico si no hay uno
      if (err['text'] == null ||
          (err['text'] is String && (err['text'] as String).trim().isEmpty)) {
        err['text'] = isSpanish
            ? 'Por favor ingresa el código de 6 dígitos.'
            : 'Please enter the 6-digit code.';
      }
      return err;
    }

    // Limpiar opciones y sugerencias de error para otros pasos
    err['options'] = <String>[];
    err['suggestions'] = <Map<String, dynamic>>[];

    return err;
  }

  Future<Map<String, dynamic>> _prepareQuestion(
    Map<String, dynamic> question,
    RegisterCubit registerCubit,
  ) async {
    final currentStepKey = questionFlow[_currentQuestionIndex];

    // � Si el paso actual es un paso de autoAdvance (como emailSuccess), avanzar automáticamente
    // Estos pasos solo muestran un mensaje y avanzan sin esperar input del usuario
    if (currentStepKey == 'emailSuccess' ||
        currentStepKey == 'emailVerification') {
      // Verificar si la pregunta tiene autoAdvance o keepTalk
      final questionData = question;
      final hasAutoAdvance = questionData['autoAdvance'] == true;
      final hasKeepTalk = questionData['keepTalk'] == true;

      if (hasAutoAdvance || hasKeepTalk) {
        debugPrint(
          '🔄 [_prepareQuestion] Paso $currentStepKey tiene autoAdvance/keepTalk - avanzando automáticamente',
        );

        // Avanzar al siguiente paso
        _currentQuestionIndex++;

        if (_currentQuestionIndex >= questionFlow.length) {
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "text": isSpanish
                ? "✅ Registro completado."
                : "✅ Registration complete.",
            "options": [],
            "step": "finished",
            "keepTalk": false,
          };
        }

        // Obtener la siguiente pregunta
        final nextQuestion = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );

        if (nextQuestion != null) {
          return await _prepareQuestion(nextQuestion, registerCubit);
        }
      }
    }

    // �🔒 Si el usuario está pre-registrado y ya tiene username reservado, mostrar confirmación
    if (currentStepKey == 'username' && registerCubit.state.isPreRegistered) {
      final reservedUsername = registerCubit.state.username;
      if (reservedUsername != null && reservedUsername.isNotEmpty) {
        final isSpanish = registerCubit.state.language == 'Español';
        debugPrint(
          '🔒 [GeminiService] Usuario pre-registrado con username: $reservedUsername - mostrando confirmación',
        );

        // Establecer flag para manejar la respuesta de confirmación
        _awaitingReservedUsernameConfirmation = true;

        // Mostrar mensaje de confirmación del username reservado
        // El usuario debe confirmar antes de continuar al siguiente paso
        return {
          "text": isSpanish
              ? "🎉 ¡Genial ${registerCubit.state.fullName ?? ''}! Tu nombre de usuario reservado es @$reservedUsername. ¿Es correcto?"
              : "🎉 Great ${registerCubit.state.fullName ?? ''}! Your reserved username is @$reservedUsername. Is this correct?",
          "options": [isSpanish ? "Sí" : "Yes", isSpanish ? "No" : "No"],
          "step": "username",
          "keepTalk": false,
        };
      }
    }

    // SI estamos en el paso de ubicación, obtener la ubicación PRIMERO
    if (currentStepKey == 'location') {
      // Si ya estamos en modo ubicación manual, NO intentamos permisos ni geolocalización.
      if (_awaitingManualLocation) {
        final isSpanish = registerCubit.state.language == 'Español';
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

      final currentLocation = registerCubit.state.location;
      // Obtener ubicación si está vacía o null
      if (currentLocation == null ||
          currentLocation.isEmpty ||
          !currentLocation.hasCityAndCountry) {
        debugPrint(
          '📍 [_prepareQuestion] Detectado paso de ubicación vacía o null - obteniendo ubicación...',
        );
        final language = registerCubit.state.language ?? _language;
        // Reintentar una vez más: justo después de conceder permisos a veces
        // llega sin ciudad/país en el primer intento.
        await registerCubit.fetchLocation(language);
        if (!(registerCubit.state.location?.hasCityAndCountry ?? false)) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await registerCubit.fetchLocation(language);
        }
        debugPrint(
          '📍 [_prepareQuestion] Ubicación obtenida: ${registerCubit.state.location?.city}',
        );

        // Si después de intentar sigue vacía/nula (típico: usuario denegó permiso),
        // pasamos automáticamente a ingreso manual.
        final after = registerCubit.state.location;
        if (after == null || after.isEmpty || !after.hasCityAndCountry) {
          _awaitingManualLocation = true;
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "text": isSpanish
                ? "Para continuar necesito tu ubicación. Como no pude obtenerla automáticamente, escríbela manualmente (solo país, ciudad y estado/departamento) así:\nPaís, Ciudad, Estado/Departamento\nEj: Colombia, Medellín, Antioquia"
                : "To continue I need your location. Since I couldn't get it automatically, type it manually (only country, city and state/region) like this:\nCountry, City, State/Region\nExample: Colombia, Medellin, Antioquia",
            "options": const <String>[],
            "step": 'regProgress.location',
            "keepTalk": false,
            "keyboardType": "text",
            "manualLocationPrompt": true,
          };
        }

        // IMPORTANT: La pregunta ya venía con {location} reemplazado ANTES de
        // hacer fetchLocation() (en getCurrentQuestion). Si no la regeneramos,
        // el texto se queda con el placeholder fallback aunque ya exista ciudad/país.
        final refreshed = AssistantFunctions.getCurrentQuestion(
          questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );
        if (refreshed != null) {
          question = refreshed;
        }
      }
    }

    // Paso de nota de voz: pedir permiso de micrófono aquí (mobile) para que el prompt
    // ocurra en el paso correspondiente y no al inicio de la app.
    if (currentStepKey == 'voiceNoteUrl' && !kIsWeb) {
      if (!_requestedMicPermissionForVoiceStep) {
        _requestedMicPermissionForVoiceStep = true;
        try {
          await Permission.microphone.request();
        } catch (e) {
          debugPrint(
            '⚠️ [GeminiService] Error solicitando permiso micrófono: $e',
          );
        }
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

    // Optional: enrich prompts via Gemini. Disabled by default to avoid any chance
    // of truncated bot messages and to keep the scripted copy consistent.
    if (_enrichEnabled) {
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

      // Defensive: if the model returns an unnaturally short snippet (often due
      // to a misconfigured max token limit), prefer the original seed text.
      if (seed.length >= 40 && text.length <= 20) {
        if (kDebugMode) {
          debugPrint(
            'Gemini enrich produced very short text (len=${text.length}) for seed len=${seed.length}; falling back to seed.',
          );
        }
        return null;
      }

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
