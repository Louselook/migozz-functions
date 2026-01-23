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

    //  Etapa 1: mensaje inicial
    if (userInput.trim().isEmpty) {
      final jsonString =
          '''
      {
        "text": "Tu correo: ${registerCubit.state.email}. ¿Es correcto?",
        "options": ["Sí", "No"],
        "step": "regProgress.sendOTP",
        "valid": true
      }
      ''';

      final initial = jsonDecode(jsonString);
      processBotResponse(initial, registerCubit: registerCubit);
      return initial;
    }

    //  Etapa 2: Decisión del usuario
    final normalized = userInput.trim().toLowerCase();
    Map<String, dynamic> decision;

    if (["si", "sí", "correcto"].contains(normalized)) {
      // Usuario confirma el email -> enviamos OTP
      decision = {
        "text": "Perfecto, te acabo de enviar un código a tu correo. 📩",
        "step": "regProgress.sendOTP",
        "valid": true,
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

    //  Etapa 3: Si dijo “Sí” → siguiente paso (ingreso de OTP)
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
