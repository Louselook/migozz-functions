// assistant_functions.dart
import 'package:migozz_app/core/services/bot/list_queestions.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class AssistantFunctions {
  /// Helper para determinar si usar español basado en el estado del cubit
  static bool _getIsSpanish(RegisterCubit cubit) {
    // Por defecto es inglés (false) si no se ha seleccionado idioma
    return cubit.state.language == 'Español';
  }

  /// Obtiene la pregunta actual del flujo
  static Map<String, dynamic> getCurrentQuestion(
    List<String> questionFlow,
    int currentIndex,
    RegisterCubit cubit,
  ) {
    if (currentIndex >= questionFlow.length) {
      return getQuestion('done', _getIsSpanish(cubit))!;
    }

    final stepKey = questionFlow[currentIndex];
    final isSpanish = _getIsSpanish(cubit);
    var question = getQuestion(stepKey, isSpanish)!;

    // Reemplazar valores dinámicos
    question = _replaceDynamicValues(question, cubit);

    return question;
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
      case 'language':
        return _evaluateLanguage(normalized, userInput);

      case 'fullName':
        return _evaluateFullName(normalized, userInput);

      case 'username':
        return _evaluateUsername(normalized, userInput);

      case 'gender':
        return _evaluateGender(normalized, userInput);

      case 'socialEcosystem':
        return {
          "step": "regProgress.socialEcosystem",
          "valid": true,
          "userResponse": userInput.trim(),
        };

      case 'location':
        return _evaluateLocation(normalized, userInput);

      case 'sendOTP': // ✅ SEPARADO de emailVerification
        return _evaluateSendOTP(normalized, userInput);

      case 'otpInput': // ✅ AGREGADO: Validar código OTP
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

  // ✅ NUEVO: Evaluación específica para sendOTP
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
    RegisterCubit cubit, // ✅ Agregar parámetro cubit
  ) {
    return getErrorMessage(stepKey, _getIsSpanish(cubit));
  }

  // ==================== REEMPLAZO DE VALORES DINÁMICOS ====================

  static Map<String, dynamic> _replaceDynamicValues(
    Map<String, dynamic> question,
    RegisterCubit cubit,
  ) {
    String text = question['text'] ?? '';

    if (text.contains('{fullName}')) {
      text = text.replaceAll('{fullName}', cubit.state.fullName ?? 'Usuario');
    }

    if (text.contains('{location}')) {
      final loc = cubit.state.location;
      final locStr = loc != null
          ? '${loc.city}, ${loc.country}'
          : 'tu ubicación';
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
    return question;
  }

  // ==================== VALIDACIONES ====================

  static Map<String, dynamic> _evaluateLanguage(
    String normalized,
    String original,
  ) {
    if (normalized.contains('es') || normalized.contains('español')) {
      return {
        "step": "regProgress.language",
        "valid": true,
        "userResponse": "Español",
      };
    } else if (normalized.contains('en') || normalized.contains('english')) {
      return {
        "step": "regProgress.language",
        "valid": true,
        "userResponse": "English",
      };
    }
    return {
      "step": "regProgress.language",
      "valid": false,
      "userResponse": original.trim(),
    };
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
    final validGenders = ['hombre', 'mujer', 'otro', 'man', 'woman', 'other'];

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

  static Map<String, dynamic> _evaluateLocation(
    String normalized,
    String original,
  ) {
    if (normalized.contains('si') ||
        normalized.contains('sí') ||
        normalized.contains('yes') ||
        normalized.contains('correcto')) {
      return {
        "step": "regProgress.location",
        "valid": true,
        "userResponse": "yes",
      };
    } else if (normalized.contains('no')) {
      return {
        "step": "regProgress.location",
        "valid": true,
        "userResponse": "no",
      };
    }
    return {
      "step": "regProgress.location",
      "valid": false,
      "userResponse": original.trim(),
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
            data["title"] ??
            data["username"] ??
            data["full_name"] ??
            key.toUpperCase();

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
