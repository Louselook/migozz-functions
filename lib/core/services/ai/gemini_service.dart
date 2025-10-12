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

import 'package:flutter/foundation.dart';
import 'package:migozz_app/core/services/ai/assistant_functions.dart';
import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class GeminiService {
  GeminiService._privateConstructor();
  static final GeminiService instance = GeminiService._privateConstructor();

  String _language = 'English';

  void ensureConfigured() {}

  int _currentQuestionIndex = 0;

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

  Future<Map<String, dynamic>> sendMessage(
    String userInput, {
    required RegisterCubit registerCubit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // === 🟢 MENSAJE INICIAL ===
    if (userInput.trim().isEmpty) {
      return _prepareQuestion(
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

      return _prepareQuestion(nextQuestion, registerCubit);
    }

    // === 🔴 SI NO ES VÁLIDO → MENSAJE DE ERROR ===
    return AssistantFunctions.getErrorMessageForStep(
          currentStepKey,
          registerCubit,
        ) ??
        decision;
  }

  Map<String, dynamic> _prepareQuestion(
    Map<String, dynamic> question,
    RegisterCubit registerCubit,
  ) {
    // 🔹 Si la pregunta necesita fotos de perfil
    if (question['showProfilePictures'] == true) {
      final pictures = AssistantFunctions.getProfilePictures(registerCubit);
      if (pictures.isNotEmpty) {
        question['profilePictures'] = pictures;
      }
    }

    return question;
  }
}
