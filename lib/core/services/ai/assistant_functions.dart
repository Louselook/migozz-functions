// assistant_functions.dart
import 'package:flutter/foundation.dart';
import 'package:migozz_app/core/services/bot/list_queestions.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class AssistantFunctions {
  /// Helper para determinar si usar español basado en el estado del cubit
  static bool _getIsSpanish(RegisterCubit cubit) {
    // Por defecto es inglés (false) si no se ha seleccionado idioma
    return cubit.state.language == 'Español';
  }

  /// Obtiene la pregunta actual del flujo
  /// Ahora devuelve Map<String,dynamic>? de forma defensiva (puede ser null)
  static Map<String, dynamic>? getCurrentQuestion(
    List<String> questionFlow,
    int currentIndex,
    RegisterCubit cubit,
  ) {
    if (currentIndex < 0 || currentIndex >= questionFlow.length) {
      return null; // evitar null check crash
    }
    try {
      if (questionFlow.isEmpty) {
        debugPrint('AssistantFunctions.getCurrentQuestion: questionFlow vacío o null');
        return null;
      }

      if (currentIndex >= questionFlow.length) {
        // intentar obtener la clave 'done'
        final doneQ = getQuestion('done', _getIsSpanish(cubit));
        if (doneQ == null) {
          debugPrint('AssistantFunctions: getQuestion("done") devolvió null');
        }
        return doneQ;
      }

      final stepKey = questionFlow[currentIndex];
      final isSpanish = _getIsSpanish(cubit);
      var question = getQuestion(stepKey, isSpanish);

      if (question == null) {
        debugPrint('AssistantFunctions: getQuestion("$stepKey") devolvió null');
        // fallback: intentar 'done'
        final doneQ = getQuestion('done', isSpanish);
        if (doneQ == null) {
          debugPrint('AssistantFunctions: fallback getQuestion("done") también devolvió null');
        }
        question = doneQ;
      }

      if (question == null) {
        // No hay pregunta válida, devolvemos null para que el caller lo maneje
        return null;
      }

      // Reemplazar valores dinámicos (esto asume question no es null)
      question = _replaceDynamicValues(question, cubit);

      return question;
    } catch (e, st) {
      debugPrint('Error en AssistantFunctions.getCurrentQuestion: $e\n$st');
      return null;
    }
  }

  /// Evalúa la respuesta del usuario según el paso actual
  static Map<String, dynamic> evaluateUserResponse(
    String userInput,
    String stepKey,
    RegisterCubit cubit,
  ) {
    final normalized = userInput.trim().toLowerCase();

    // 👇 Detección de preguntas del tipo "why/para qué/por qué"
    final isWhy =
        normalized == 'why' ||
        normalized == 'why?' ||
        normalized.contains('why ') ||
        normalized.contains(' why') ||
        normalized.contains('por qué') ||
        normalized.contains('por que') ||
        normalized.contains('para qué') ||
        normalized.contains('para que');

    switch (stepKey) {
      case 'fullName':
        return _evaluateFullName(normalized, userInput);

      case 'username':
        return _evaluateUsername(normalized, userInput);

      case 'gender':
        return _evaluateGender(normalized, userInput);

      case 'location':
        return _evaluateLocation(normalized, userInput, cubit);

      case 'sendOTP': //  SEPARADO de emailVerification
        return _evaluateSendOTP(normalized, userInput);

      case 'otpInput': // AGREGADO: Validar código OTP
        return _evaluateOTP(normalized, userInput, cubit);

      case 'avatarUrl':
      case 'phone':
      case 'voiceNoteUrl':
        return {
          "step": "regProgress.$stepKey",
          "valid": true,
          if (isWhy) "explainWhy": true,
          "userResponse": userInput.trim(),
        };

      default:
        return {
          "step": "regProgress.$stepKey",
          "valid": true,
          if (isWhy) "explainWhy": true,
          "userResponse": userInput.trim(),
        };
    }
  }

  // Evaluación específica para sendOTP
  static Map<String, dynamic> _evaluateSendOTP(
    String normalized,
    String original,
  ) {
    if (normalized.contains('si') ||
        normalized.contains('sí') ||
        normalized.contains('yes') ||
        normalized.contains('correcto')) {
      return {
        "step": "regProgress.sendOTP",
        "valid": true,
        "userResponse": "Sí",
      };
    } else if (normalized.contains('no')) {
      return {
        "step": "regProgress.sendOTP",
        "valid": false,
        "userResponse": "No",
      };
    }
    return {
      "step": "regProgress.sendOTP",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  /// Obtiene mensaje de error desde list_questions
  static Map<String, dynamic>? getErrorMessageForStep(
    String stepKey,
    RegisterCubit cubit, // Agregar parámetro cubit
  ) {
    return getErrorMessage(stepKey, _getIsSpanish(cubit));
  }

  // ==================== REEMPLAZO DE VALORES DINÁMICOS ====================

  static Map<String, dynamic> _replaceDynamicValues(
    Map<String, dynamic> question,
    RegisterCubit cubit,
  ) {
    try {
      String text = question['text'] ?? '';

      if (text.contains('{fullName}')) {
        text = text.replaceAll('{fullName}', cubit.state.fullName ?? 'Usuario');
      }

      if (text.contains('{location}')) {
        final loc = cubit.state.location;
        String locStr;

        // Manejo mejorado de ubicación
        if (loc != null && !loc.isEmpty) {
          // Si tiene ubicación válida, mostrarla
          locStr = '${loc.city}, ${loc.country}';
        } else {
          final isSpanish = _getIsSpanish(cubit);
          locStr = isSpanish ? 'tu ubicación' : 'your location';
        }

        text = text.replaceAll('{location}', locStr);
      }

      if (text.contains('{email}')) {
        text = text.replaceAll('{email}', cubit.state.email ?? 'tu correo');
      }

      if (text.contains('{socialEcosystem}')) {
        final networks =
            cubit.state.socialEcosystem?.map((e) => e.keys.first).join(', ') ??
            'tus redes sociales';
        text = text.replaceAll('{socialEcosystem}', networks);
      }

      question['text'] = text;
    } catch (e, st) {
      debugPrint('Error en _replaceDynamicValues: $e\n$st');
    }

    return question;
  }

  static Map<String, dynamic> _evaluateFullName(
    String normalized,
    String original,
  ) {
    final words = original
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.length >= 2) {
      return {
        "step": "regProgress.fullName",
        "valid": true,
        "userResponse": original.trim(),
      };
    }
    return {
      "step": "regProgress.fullName",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  static Map<String, dynamic> _evaluateUsername(
    String normalized,
    String original,
  ) {
    if (original.trim().length >= 3 && !original.contains(' ')) {
      return {
        "step": "regProgress.username",
        "valid": true,
        "userResponse": original.trim(),
      };
    }
    return {
      "step": "regProgress.username",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  static Map<String, dynamic> _evaluateGender(
    String normalized,
    String original,
  ) {
    final validGenders = ['hombre', 'mujer', 'otro', 'male', 'female', 'other'];

    if (validGenders.any((g) => normalized.contains(g))) {
      return {
        "step": "regProgress.gender",
        "valid": true,
        "userResponse": original.trim(),
      };
    }
    return {
      "step": "regProgress.gender",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  // ACTUALIZADO: Evaluación de ubicación con 3 opciones
  static Map<String, dynamic> _evaluateLocation(
    String normalized,
    String original,
    RegisterCubit cubit,
  ) {
    final isSpanish = _getIsSpanish(cubit);

    // Opción 1: Usuario confirma ubicación (Sí)
    if (normalized == 'sí' ||
        normalized == 'si' ||
        normalized == 'yes' ||
        normalized.contains('correcto')) {
      return {
        "step": "regProgress.location",
        "valid": true,
        "userResponse": "Sí",
        "confirmLocation": true, //  Bandera para confirmar
      };
    }

    // Opción 2: Usuario rechaza usar ubicación (No)
    if (normalized == 'no') {
      return {
        "step": "regProgress.location",
        "valid": true, //  IMPORTANTE: Es válido rechazar
        "userResponse": "No",
        "emptyLocation": true, //  Bandera para ubicación vacía
      };
    }

    // Opción 3: Usuario reporta ubicación incorrecta
    if (normalized.contains('incorrecta') ||
        normalized.contains('incorrect') ||
        normalized == 'ubicación incorrecta' ||
        normalized == 'incorrect location') {
      return {
        "step": "regProgress.location",
        "valid": false, //  No es válido, debe reintentar
        "userResponse": original.trim(),
        "text": isSpanish
            ? "Entendido. Por favor, ingresa tu ubicación manualmente o intenta detectarla nuevamente."
            : "Understood. Please enter your location manually or try detecting it again.",
        "options": isSpanish
            ? ["Sí", "No", "Ubicación incorrecta"]
            : ["Yes", "No", "Incorrect location"],
      };
    }

    // Respuesta no válida
    return {
      "step": "regProgress.location",
      "valid": false,
      "userResponse": original.trim(),
      "text": isSpanish
          ? "Por favor, selecciona una opción válida: Sí, No, o Ubicación incorrecta."
          : "Please select a valid option: Yes, No, or Incorrect location.",
      "options": isSpanish
          ? ["Sí", "No", "Ubicación incorrecta"]
          : ["Yes", "No", "Incorrect location"],
    };
  }

  static Map<String, dynamic> _evaluateOTP(
    String normalized,
    String original,
    RegisterCubit cubit,
  ) {
    if (RegExp(r'^\d+$').hasMatch(original.trim())) {
      return {
        "step": "regProgress.emailVerification",
        "valid": true,
        "userResponse": original.trim(),
      };
    }
    return {
      "step": "regProgress.emailVerification",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  static List<Map<String, String>> getProfilePictures(RegisterCubit cubit) {
    final platforms = cubit.state.socialEcosystem ?? [];
    final pictureCards = <Map<String, String>>[];

    for (final platform in platforms) {
      final key = platform.keys.first;
      final data = platform[key] as Map<String, dynamic>;

      final possibleKeys = [
        "profile_image_url",
        "profile_pic_url",
        "avatar_url",
        "picture",
      ];

      String? imageUrl;
      for (final imgKey in possibleKeys) {
        if (data[imgKey] != null && (data[imgKey] as String).isNotEmpty) {
          imageUrl = data[imgKey] as String;
          break;
        }
      }

      if (imageUrl != null) {
        final label =
            data["title"] ?? data["username"] ?? data["full_name"] ?? key.toUpperCase();

        pictureCards.add({
          "imageUrl": imageUrl,
          "label": label,
          "platform": key,
        });
      }
    }

    return pictureCards;
  }
}
