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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/core/services/ai/chat_validation_min.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class GeminiService {
  GeminiService._privateConstructor();
  static final GeminiService instance = GeminiService._privateConstructor();

  void ensureConfigured() {}

  Future<Map<String, dynamic>> sendMessage(
    String userInput, {
    required RegisterCubit registerCubit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // === 🟢 Etapa 1: mensaje inicial ===
    if (userInput.trim().isEmpty) {
      final jsonString = '''
      {
        "text": "Personalicemos tu perfil. Puedo sugerirte una foto de tus redes sociales conectadas o puedes subir una nueva. ¿Cuál prefieres? 📸",
        "step": "regProgress.avatarUrl"

      }
      ''';
      // "step": "regProgress.sendOTP",
      // "valid": false
      final initial = jsonDecode(jsonString);
      processBotResponse(initial, registerCubit: registerCubit);
      return initial;
    }

    // === 🟡 Etapa 2: Decisión del usuario ===
    final normalized = userInput.trim().toLowerCase();
    Map<String, dynamic> decision;

    if (["si", "sí", "correcto"].contains(normalized)) {
      // Usuario confirma el email -> enviamos OTP
      decision = {
        "text": "Perfecto, te acabo de enviar un código a tu correo. 📩",
        "step": "regProgress.sendOTP",
        "valid": false,
        "userResponse": userInput.trim(),
      };
    } else if (["no", "cambiar"].contains(normalized)) {
      // Usuario quiere cambiar el email
      decision = {
        "text": "De acuerdo, escribe tu correo electrónico nuevamente.",
        "step": "regProgress.emailVerification",
        "valid": false,
        "userResponse": userInput.trim(),
      };
    } else {
      // Respuesta no válida
      decision = {
        "text": "Por favor responde 'Sí' o 'No'.",
        "options": ["Sí", "No"],
        "step": "regProgress.sendOTP",
        "valid": false,
      };
    }

    debugPrint('🤖 Decisión IA: $decision');
    await processBotResponse(decision, registerCubit: registerCubit);

    // === 🟣 Etapa 3: Si dijo “Sí” → siguiente paso (ingreso de OTP)
    if (decision["valid"] == true &&
        decision["step"] == "regProgress.sendOTP") {
      final nextMessage = {
        "text":
            "Por favor ingresa el código de verificación que recibiste por correo.",
        "step": "regProgress.emailVerification",
        "valid": true,
      };

      processBotResponse(nextMessage, registerCubit: registerCubit);
      return nextMessage;
    }

    return decision;
  }
}
