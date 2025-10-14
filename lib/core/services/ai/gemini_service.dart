// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
// import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

// class GeminiService {
//   GeminiService._private();
//   static final GeminiService instance = GeminiService._private();

//   late GenerativeModel _model;
//   bool _isConfigured = false;
//   bool get isConfigured => _isConfigured;

//   // 🔹 Inicializa el modelo solo una vez
//   void ensureConfigured() {
//     if (_isConfigured) return;

//     final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
//     if (apiKey.trim().isEmpty) {
//       debugPrint('❌ [GeminiService] API key no configurada.');
//       return;
//     }

//     try {
//       _model = GenerativeModel(
//         model: 'gemini-2.0-flash',
//         apiKey: apiKey,
//         generationConfig: GenerationConfig(
//           temperature: 0.5,
//           maxOutputTokens: 250,
//         ),
//       );
//       _isConfigured = true;
//       debugPrint('✅ [GeminiService] Configurado correctamente.');
//     } catch (e) {
//       debugPrint('❌ [GeminiService] Error al configurar: $e');
//     }
//   }

//   /// 🔸 Envía mensaje al modelo y procesa con el cubit
//   Future<Map<String, dynamic>> sendMessage(
//     String userInput, {
//     required RegisterCubit registerCubit,
//   }) async {
//     if (!_isConfigured) {
//       return {
//         "text": "⚠️ Servicio no configurado",
//         "valid": false,
//         "options": [],
//         "action": 0,
//       };
//     }

//     // 🧠 Prompt base para dar estructura
//     final prompt =
//         """
// Eres un asistente para registro paso a paso.
// Responde SIEMPRE en JSON válido como el siguiente formato:

// {
//   "text": "Mensaje corto para el usuario",
//   "options": ["opcion1","opcion2"],
//   "valid": true,
//   "step": "regProgress.language",
//   "action": 0,
//   "extracted": "valor_extraido",
//   "call": "nombre_de_funcion"
// }

// Usuario: "$userInput"
// """;

//     try {
//       final resp = await _model.generateContent([Content.text(prompt)]);
//       final rawText = resp.text?.trim() ?? '';

//       // 🧩 Normaliza JSON de forma segura
//       Map<String, dynamic> jsonResponse;
//       try {
//         jsonResponse = _looseJsonDecode(rawText) ?? {"text": rawText};
//       } catch (_) {
//         jsonResponse = {"text": rawText};
//       }

//       // 🔍 Procesa la respuesta con tu función lógica (usa el cubit)
//       processBotResponse(jsonResponse, registerCubit: registerCubit);

//       return {
//         "text": jsonResponse["text"] ?? "⚠️ Respuesta vacía",
//         "options": List<String>.from(jsonResponse["options"] ?? []),
//         "valid": jsonResponse["valid"] ?? false,
//         "step": jsonResponse["step"],
//         "action": jsonResponse["action"],
//         "extracted": jsonResponse["extracted"],
//         "call": jsonResponse["call"],
//       };
//     } catch (e) {
//       debugPrint('❌ [GeminiService] Error generando respuesta: $e');
//       return {
//         "text": "⚠️ Error generando respuesta",
//         "valid": false,
//         "options": [],
//         "action": 0,
//       };
//     }
//   }

//   /// 🔧 Intenta corregir comillas o JSON mal formateado
//   Map<String, dynamic>? _looseJsonDecode(String s) {
//     try {
//       final fixed = s
//           .replaceAll(RegExp(r'[\u2018\u2019\u201C\u201D]'), '"')
//           .replaceAll(RegExp(r',\s*([}\]])'), r'$1');
//       return jsonDecode(fixed) as Map<String, dynamic>;
//     } catch (_) {
//       return null;
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:migozz_app/core/services/ai/assistant_functions.dart';
import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class GeminiService {
  GeminiService._privateConstructor();
  static final GeminiService instance = GeminiService._privateConstructor();

  String _language = 'English';
  GenerativeModel? _model;
  ChatSession? _session;
  // Timeout máximo para llamadas de enriquecimiento IA (evita que la UI quede colgada)
  static const Duration _enrichTimeout = Duration(seconds: 8);
  String _modelName = 'gemini-2.0-flash'; // default por compatibilidad
  double _temperature = 0.4;
  int _maxOutputTokens = 180;
  bool _allowRuntimeSwitch = false; // por defecto NO alterna en runtime

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
      // Permitir override por .env
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

  int _currentQuestionIndex = 4;

  final List<String> _questionFlow = [
    'language', // 0
    'fullName', // 1
    'username', // 2
    'gender', // 3
    'socialEcosystem', // 4
    'location', // 5
    'sendOTP', // 6
    'emailVerification', // 7 - "te envié el código" (keepTalk: true, se salta)
    'otpInput', // 8 - Pedir código
    'emailSuccess', // 9 - ✅ "¡Felicidades!" (ahora keepTalk: false, se muestra)
    'avatarUrl', // 10
    'phone', // 11
    'voiceNoteUrl', // 12
    'category', // 13
  ];

  String get currentLanguage => _language;
  void setLanguage(String lang) {
    _language = lang;
    debugPrint('🌐 Idioma establecido: $_language');
  }

  void setStartIndex(int index) {
    if (index >= 0 && index < _questionFlow.length) {
      _currentQuestionIndex = index;
      debugPrint('📍 Índice inicial: $index (${_questionFlow[index]})');
    }
  }

  void reset() {
    _currentQuestionIndex = 0;
  }

  // Permite cambiar el modelo en runtime sin reiniciar la app.
  // Reconfigura la sesión manteniendo el flujo actual.
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

    // Reiniciar modelo/sesión y reconfigurar
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

    // === 🟢 MENSAJE INICIAL ===
    if (userInput.trim().isEmpty) {
      return await _prepareQuestion(
        AssistantFunctions.getCurrentQuestion(
          _questionFlow,
          _currentQuestionIndex,
          registerCubit,
        ),
        registerCubit,
      );
    }

    // === 🟡 EVALUAR RESPUESTA ===
    final currentStepKey = _questionFlow[_currentQuestionIndex];
    final decision = AssistantFunctions.evaluateUserResponse(
      userInput,
      currentStepKey,
      registerCubit,
    );

    debugPrint('🤖 Decisión: $decision');

    // === 🔵 SI ES VÁLIDO → PROCESAR Y VERIFICAR ===
    if (decision['valid'] == true) {
      // ✅ PRIMERO procesa y verifica si hay errores
      final processResult = await processBotResponse(
        decision,
        registerCubit: registerCubit,
      );

      // ⚠️ MANEJO DE ERRORES (OTP incorrecto, etc.)
      if (processResult != null && processResult['error'] == true) {
        debugPrint('❌ Error en procesamiento: ${processResult['message']}');

        // Si es error de OTP inválido, devolver mensaje de error
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
            "isError": true, // ✅ Flag para que la UI lo muestre como error
          };
        }

        return processResult;
      }

      // ✅ Si no hubo errores, AHORA SÍ avanzar
      _currentQuestionIndex++;

      var nextQuestion = AssistantFunctions.getCurrentQuestion(
        _questionFlow,
        _currentQuestionIndex,
        registerCubit,
      );

      // ✅ Manejo de keepTalk (solo para mensajes intermedios)
      while (nextQuestion['keepTalk'] == true) {
        debugPrint(
          '⏩ Saltando mensaje keepTalk: ${_questionFlow[_currentQuestionIndex]}',
        );
        _currentQuestionIndex++;
        if (_currentQuestionIndex >= _questionFlow.length) break;

        nextQuestion = AssistantFunctions.getCurrentQuestion(
          _questionFlow,
          _currentQuestionIndex,
          registerCubit,
        );
      }

      return await _prepareQuestion(nextQuestion, registerCubit);
    }

    // === 🔴 SI NO ES VÁLIDO → MENSAJE DE ERROR ===
    // Si el usuario pidió una explicación ("why?/¿para qué?") mostramos
    // un mensaje corto y repetimos la misma pregunta automáticamente.
    if (decision['explainWhy'] == true) {
      final isSpanish = registerCubit.state.language == 'Español';
      final explain =
          _whyExplanation(currentStepKey, isSpanish) ??
          (isSpanish
              ? 'Con gusto. Te explico brevemente y continuamos.'
              : 'Sure. Let me explain briefly and continue.');
      return {
        "text": explain,
        "options": const <String>[],
        "step": 'regProgress.$currentStepKey',
        "keepTalk": true, // mensaje contextual
        "explainAndRepeat": true, // la UI repetirá la pregunta actual
      };
    }

    final err =
        AssistantFunctions.getErrorMessageForStep(
          currentStepKey,
          registerCubit,
        ) ??
        Map<String, dynamic>.from(decision);

    // Enriquecer texto de error con IA (opcional, con timeout)
    final enriched = await _enrichTextIfPossible(
      baseText: err['text']?.toString(),
      stepKey: currentStepKey,
      registerCubit: registerCubit,
      purpose: 'error',
    );
    if (enriched != null) err['text'] = enriched;

    // Fallback robusto: si por alguna razón no hay texto, proporcionar uno genérico
    if (err['text'] == null ||
        (err['text'] is String && (err['text'] as String).trim().isEmpty)) {
      final isSpanish = registerCubit.state.language == 'Español';
      err['text'] = isSpanish
          ? 'Por favor ingresa un valor válido.'
          : 'Please enter a valid value.';
      // Asegurar que la UI no quede esperando interacción extraña
      err['keepTalk'] = false;
    }
    return err;
  }

  Future<Map<String, dynamic>> _prepareQuestion(
    Map<String, dynamic> question,
    RegisterCubit registerCubit,
  ) async {
    // 🔹 Si la pregunta necesita fotos de perfil
    if (question['showProfilePictures'] == true) {
      final pictures = AssistantFunctions.getProfilePictures(registerCubit);
      if (pictures.isNotEmpty) {
        question['profilePictures'] = pictures;
      }
    }
    // Enriquecer el texto de la pregunta manteniendo opciones/paso
    final enriched = await _enrichTextIfPossible(
      baseText: question['text']?.toString(),
      stepKey:
          question['step']?.toString() ?? _questionFlow[_currentQuestionIndex],
      registerCubit: registerCubit,
      purpose: 'question',
      options: (question['options'] is List)
          ? List<String>.from(question['options'])
          : const <String>[],
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
    required String purpose, // 'question' | 'error'
    List<String> options = const <String>[],
  }) async {
    ensureConfigured();
    if (_session == null) return null; // IA deshabilitada

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
      // Limitar longitud por seguridad
      return text.length > 180 ? text.substring(0, 180) : text;
    } on TimeoutException {
      if (kDebugMode) debugPrint('Gemini enrich timeout ($_enrichTimeout)');
      return null; // No bloquear: devolvemos null para usar el texto base
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
    final es = <String, String>{
      'phone':
          'Tu número nos ayuda a proteger tu cuenta y permitir funciones como recuperación y verificación en dos pasos.',
      'voiceNoteUrl':
          'Una nota de voz breve (5–10s) ayuda a que otros te conozcan mejor y hace tu perfil más auténtico.',
      'avatarUrl':
          'Una foto hace tu perfil reconocible y confiable. Puedes elegir de tus redes o subir una nueva.',
      'sendOTP':
          'Verificamos tu correo para garantizar la seguridad y que podamos contactarte si es necesario.',
      'location':
          'La ubicación mejora tus recomendaciones y conexiones cercanas. No compartimos tu ubicación exacta.',
    };
    final en = <String, String>{
      'phone':
          "Your phone helps secure your account and enables features like recovery and two-step verification.",
      'voiceNoteUrl':
          "A short voice note (5–10s) helps others know you better and makes your profile feel authentic.",
      'avatarUrl':
          "A profile photo makes you recognizable and trustworthy. Pick from socials or upload a new one.",
      'sendOTP':
          "We verify your email to keep your account secure and ensure we can reach you if needed.",
      'location':
          "Location improves recommendations and nearby connections. We don't share your exact location.",
    };
    return (isSpanish ? es[stepKey] : en[stepKey]);
  }
}
