// assistant_functions.dart
import 'package:flutter/foundation.dart';
import 'package:migozz_app/core/services/bot/list_queestions.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';

class AssistantFunctions {
  /// Helper para determinar si usar español basado en el estado del cubit
  static bool _getIsSpanish(RegisterCubit cubit) {
    // Por defecto es inglés (false) si no se ha seleccionado idioma
    return cubit.state.language == 'Español';
  }

  /// Obtiene la pregunta actual del flujo
  /// Ahora devuelve `Map<String, dynamic>?` de forma defensiva (puede ser null)
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
        debugPrint(
          'AssistantFunctions.getCurrentQuestion: questionFlow vacío o null',
        );
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
          debugPrint(
            'AssistantFunctions: fallback getQuestion("done") también devolvió null',
          );
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

    // Normalización ligera para detectar preguntas tipo "por qué" aunque vengan
    // sin signos o con variaciones comunes (porque/porqué/por que).
    final normalizedPlain = normalized
        .replaceAll(RegExp(r'[¿?¡!.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 👇 DETECCIÓN DE CAMBIOS DE RESPUESTAS ANTERIORES
    final wantToChange = _detectChangeRequest(normalized, cubit);
    if (wantToChange != null) {
      return wantToChange;
    }

    // 👇 Detección de preguntas del tipo "why/para qué/por qué".
    // Importante: muchos usuarios escriben "porque" (1 palabra) sin signos.
    final isWhy =
      normalizedPlain == 'why' ||
      normalizedPlain.startsWith('why ') ||
      normalizedPlain.endsWith(' why') ||
      normalizedPlain.contains(' why ') ||
      normalizedPlain.contains('por qué') ||
      normalizedPlain.contains('por que') ||
      normalizedPlain.contains('porqué') ||
      normalizedPlain == 'porque' ||
      normalizedPlain.startsWith('porque ') ||
      normalizedPlain.contains(' para qué') ||
      normalizedPlain.contains(' para que') ||
      normalizedPlain.contains(' paraqué') ||
      normalizedPlain == 'para que' ||
      normalizedPlain == 'para qué';

    switch (stepKey) {
      case 'fullName':
        return _evaluateFullName(normalized, userInput);

      case 'username':
        return _evaluateUsername(normalized, userInput);

      case 'gender':
        return _evaluateGender(normalized, userInput);

      case 'location':
        return _evaluateLocation(normalized, userInput, cubit);

      // Paso interno: ingreso manual de ubicación (país/estado/ciudad)
      case 'locationManual':
        if (isWhy) {
          return {
            "step": "regProgress.location",
            "valid": false,
            "isWhy": true,
            // Usar el contexto de 'location' (no 'locationManual')
            "field": "location",
            "userResponse": userInput.trim(),
          };
        }
        return _evaluateManualLocation(userInput, cubit);

      case 'sendOTP': //  SEPARADO de emailVerification
        return _evaluateSendOTP(normalized, userInput);

      case 'emailChange': // NUEVO: Cambiar email
        return _evaluateEmailChange(normalized, userInput);

      case 'otpInput': // AGREGADO: Validar código OTP
        return _evaluateOTP(normalized, userInput, cubit);

      case 'voiceNoteUrl':
        return _evaluateVoiceNoteUrl(normalized, userInput, cubit, isWhy);

      case 'avatarUrl':
      case 'phone':
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

  static Map<String, dynamic> _evaluateVoiceNoteUrl(
    String normalized,
    String original,
    RegisterCubit cubit,
    bool isWhy,
  ) {
    final isSpanish = _getIsSpanish(cubit);
    final text = original.trim();

    // Si el usuario pregunta "por qué/para qué/why", NO tomarlo como respuesta válida.
    // Solo dar contexto y volver a pedir el audio.
    if (isWhy) {
      return {
        "step": "regProgress.voiceNoteUrl",
        "valid": false,
        "explainWhy": true,
        "userResponse": text,
      };
    }

    // Permitir Skip explícito
    if (normalized == 'skip') {
      return {
        "step": "regProgress.voiceNoteUrl",
        "valid": true,
        "userResponse": 'Skip',
      };
    }

    // Si ya hay un archivo/audio confirmado en el cubit, aceptar.
    // (Esto ocurre cuando el AudioChatHandler ya guardó el audio y el flujo avanza.)
    final voiceFile = cubit.voiceNoteFile;
    if (voiceFile != null) {
      return {
        "step": "regProgress.voiceNoteUrl",
        "valid": true,
        "userResponse": text,
      };
    }

    // Si el usuario envía texto al azar (sin audio), no avanzar.
    // Pedir que grabe/envíe la nota de voz.
    return {
      "step": "regProgress.voiceNoteUrl",
      "valid": false,
      "userResponse": text,
      "text": isSpanish
          ? 'Para continuar, graba una nota de voz (1-10s) manteniendo presionado el micrófono, o escribe "Skip" si deseas omitirla.'
          : 'To continue, record a voice note (1-10s) by holding the microphone, or type "Skip" to skip it.',
    };
  }

  static Map<String, dynamic> _evaluateManualLocation(
    String original,
    RegisterCubit cubit,
  ) {
    final isSpanish = _getIsSpanish(cubit);
    final text = original.trim();

    // Formatos soportados:
    // 1) "Colombia, Antioquia, Medellín"
    // 2) "País: Colombia, Estado: Antioquia, Ciudad: Medellín" (cualquier orden)
    // 3) "Country: Colombia, State: Antioquia, City: Medellin"

    String country = '';
    String state = '';
    String city = '';

    final lower = text.toLowerCase();
    final hasLabels =
        lower.contains('país') ||
        lower.contains('pais') ||
        lower.contains('estado') ||
        lower.contains('departamento') ||
        lower.contains('ciudad') ||
        lower.contains('country') ||
        lower.contains('state') ||
        lower.contains('city');

    if (hasLabels) {
      // Parse tipo "key: value" separado por comas
      final parts = text.split(',');
      for (final raw in parts) {
        final p = raw.trim();
        final idx = p.indexOf(':');
        if (idx <= 0) continue;
        final key = p.substring(0, idx).trim().toLowerCase();
        final value = p.substring(idx + 1).trim();
        if (value.isEmpty) continue;

        if (key.contains('país') || key.contains('pais') || key.contains('country')) {
          country = value;
        } else if (key.contains('estado') ||
            key.contains('departamento') ||
            key.contains('state')) {
          state = value;
        } else if (key.contains('ciudad') || key.contains('city')) {
          city = value;
        }
      }
    } else {
      // Parse simple por comas (según el prompt): Country, City, State
      final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length >= 3) {
        country = parts[0];
        city = parts[1];
        state = parts[2];
      }
    }

    final hasMinimum = country.isNotEmpty && state.isNotEmpty && city.isNotEmpty;
    if (!hasMinimum) {
      return {
        "step": "regProgress.location",
        "valid": false,
        "manualLocation": true,
        "userResponse": text,
        "text": isSpanish
            ? "Por favor ingresa tu ubicación como: País, Ciudad, Estado/Departamento.\nEj: Colombia, Medellín, Antioquia\n\nTambién puedes usar etiquetas: País: Colombia, Ciudad: Medellín, Estado: Antioquia"
            : "Please enter your location as: Country, City, State/Region.\nExample: Colombia, Medellin, Antioquia\n\nYou can also use labels: Country: Colombia, City: Medellin, State: Antioquia",
      };
    }

    return {
      "step": "regProgress.location",
      "valid": true,
      "manualLocation": true,
      "userResponse": text,
      "country": country,
      "state": state,
      "city": city,
    };
  }

  /// Detecta si el usuario quiere cambiar una respuesta anterior
  /// Retorna un mapa con `"changeField"` si encuentra una solicitud de cambio
  static Map<String, dynamic>? _detectChangeRequest(
    String normalized,
    RegisterCubit cubit,
  ) {
    final isSpanish = _getIsSpanish(cubit);

    // Patrones para detectar cambios
    final changePatterns = [
      'me equivoque',
      'me equivoqué',
      'cometí un error',
      'i made a mistake',
      'wrong',
      'incorrect',
      'podemos cambiar',
      'can we change',
      'quiero cambiar',
      'want to change',
      'change my',
      'cambiar mi',
      'cambiar el',
      'change the',
      'volver atrás',
      'go back',
      'back',
      'atrás',
      'redo',
      'rehacer',
      'reset',
      'otra vez',
      'again',
      'de nuevo',
    ];

    final detectedChange = changePatterns.any((p) => normalized.contains(p));

    if (!detectedChange) return null;

    // Detectar a QUÉ campo se refiere
    // IMPORTANTE: Orden importa para evitar confusiones.
    // Ej: "nombre de usuario" contiene "nombre" pero debe mapear a username.
    String? targetField;

    final wantsUsername =
        normalized.contains('nombre de usuario') ||
        normalized.contains('username') ||
        normalized.contains('usuario') ||
        normalized.contains('apodo') ||
        normalized.contains('nick') ||
        normalized.contains('nickname');

    final wantsFullName =
        normalized.contains('nombre completo') ||
        normalized.contains('mi nombre') ||
        normalized.contains('full name') ||
        (normalized.contains('nombre') && !wantsUsername);

    if (wantsUsername) {
      targetField = 'username';
    } else if (wantsFullName) {
      targetField = 'fullName';
    } else if (normalized.contains('redes sociales') ||
        normalized.contains('redes') ||
        normalized.contains('social ecosystem') ||
        normalized.contains('social networks') ||
        normalized.contains('networks') ||
        normalized.contains('social')) {
      targetField = 'socialEcosystem';
    } else if (normalized.contains('foto') ||
        normalized.contains('imagen') ||
        normalized.contains('avatar') ||
        normalized.contains('profile picture') ||
        normalized.contains('picture')) {
      targetField = 'avatarUrl';
    } else if (normalized.contains('correo') || normalized.contains('email')) {
      targetField = 'sendOTP';

      // BLOQUEAR: Si el correo ya fue verificado, no permitir cambio
      if (cubit.state.emailVerification == EmailVerification.success) {
        return {
          "step": "regProgress.changeRequest",
          "valid": false,
          "changeRequest": true,
          "targetField": targetField,
          "blocked": true,
          "message": isSpanish
              ? "⚠️ Tu correo ya ha sido verificado. No puedes cambiarlo de nuevo."
              : "⚠️ Your email has already been verified. You cannot change it again.",
        };
      }
    } else if (normalized.contains('ubicación') ||
        normalized.contains('ubicacion') ||
        normalized.contains('dirección') ||
        normalized.contains('direccion') ||
        normalized.contains('location') ||
        normalized.contains('address')) {
      targetField = 'location';
    } else if (normalized.contains('teléfono') ||
        normalized.contains('telefono') ||
        normalized.contains('phone')) {
      targetField = 'phone';
    }

    return {
      "step": "regProgress.changeRequest",
      "valid": false, // No avanzamos hasta que se especifique qué cambiar
      "changeRequest": true,
      if (targetField != null) "targetField": targetField,
      "message": isSpanish
          ? "Entendido, podemos cambiar lo que necesites. ¿Qué información quieres actualizar?"
          : "Understood! What would you like to update?",
    };
  }

  // Evaluación específica para sendOTP
  static Map<String, dynamic> _evaluateSendOTP(
    String normalized,
    String original,
  ) {
    // Detectar preguntas "why"
    final isWhy = _isWhyQuestion(
      normalized,
      false,
    ); // Usar default false para detectar ambos idiomas
    if (isWhy) {
      return {
        "step": "regProgress.sendOTP",
        "valid": false,
        "isWhy": true,
        "field": "sendOTP",
      };
    }

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
        "valid": true,
        "userResponse": "No",
        "changeEmail": true, // Bandera para indicar cambio de email
      };
    }
    return {
      "step": "regProgress.sendOTP",
      "valid": false,
      "userResponse": original.trim(),
    };
  }

  // NUEVO: Evaluación para cambio de correo electrónico
  static Map<String, dynamic> _evaluateEmailChange(
    String normalized,
    String original,
  ) {
    // Validar formato básico de email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (emailRegex.hasMatch(original.trim())) {
      return {
        "step": "regProgress.emailChange",
        "valid": true,
        "userResponse": original.trim(),
      };
    }
    return {
      "step": "regProgress.emailChange",
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
    // Detectar preguntas "why"
    final isWhy = _isWhyQuestion(normalized, false);
    if (isWhy) {
      return {
        "step": "regProgress.fullName",
        "valid": false,
        "isWhy": true,
        "field": "fullName",
      };
    }

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
    // Detectar preguntas "why" PRIMERO
    final isWhy = _isWhyQuestion(normalized, false);
    if (isWhy) {
      return {
        "step": "regProgress.username",
        "valid": false,
        "isWhy": true,
        "field": "username",
      };
    }

    // Detectar si el usuario pide más sugerencias
    final wantsMoreSuggestions =
        normalized.contains('recomiendame mas') ||
        normalized.contains('recomendame mas') ||
        normalized.contains('recommend more') ||
        normalized.contains('give me more') ||
        normalized.contains('otra') ||
        normalized.contains('otro') ||
        normalized.contains('mas sugerencias') ||
        normalized.contains('mas') &&
            (normalized.contains('nombre') || normalized.contains('usuario')) ||
        normalized == 'otro' ||
        normalized == 'otra' ||
        normalized == 'mas' ||
        normalized.contains('no me gusta') ||
        normalized.contains('not happy') ||
        normalized.contains('i dont like');

    if (wantsMoreSuggestions) {
      return {
        "step": "regProgress.username",
        "valid": false,
        "userResponse": original.trim(),
        "requestMoreSuggestions": true,
      };
    }

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

    // IMPORTANTE: Detectar preguntas "why" ANTES de validar respuestas
    final isWhy = _isWhyQuestion(normalized, isSpanish);
    if (isWhy) {
      return {
        "step": "regProgress.location",
        "valid": false,
        "isWhy": true, // Flag para gemini_service que lance explicación
        "userResponse": original.trim(),
        "field": "location",
      };
    }

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
        // En vez de saltar el paso, pedimos ubicación manual.
        "valid": false,
        "userResponse": original.trim(),
        "manualLocationRequest": true,
      };
    }

    // Opción 3: Usuario reporta ubicación incorrecta
    if (normalized.contains('incorrecta') ||
        normalized.contains('incorrect') ||
        normalized == 'incorrect location') {
      return {
        "step": "regProgress.location",
        "valid": false,
        "userResponse": original.trim(),
        "manualLocationRequest": true,
      };
    }

    // Respuesta no válida
    return {
      "step": "regProgress.location",
      "valid": false,
      "userResponse": original.trim(),
      "text": isSpanish
          ? "Por favor, selecciona una opción válida: Sí o No."
          : "Please select a valid option: Yes or No.",
      "options": isSpanish ? ["Sí", "No"] : ["Yes", "No"],
    };
  }

  static Map<String, dynamic> _evaluateOTP(
    String normalized,
    String original,
    RegisterCubit cubit,
  ) {
    final isSpanish = _getIsSpanish(cubit);

    // Detectar preguntas "why" PRIMERO
    final isWhy = _isWhyQuestion(normalized, isSpanish);
    if (isWhy) {
      return {
        "step": "regProgress.emailVerification",
        "valid": false,
        "isWhy": true,
        "field": "sendOTP", // OTP es parte del proceso de sendOTP
      };
    }

    // BLOQUEAR: Si el correo ya fue verificado, no permitir reenvío
    if (cubit.state.emailVerification == EmailVerification.success) {
      // Detectar si el usuario quiere reenviar código
      if (normalized.contains('reenviar') ||
          normalized.contains('resend') ||
          normalized.contains('send again') ||
          normalized.contains('enviar de nuevo')) {
        return {
          "step": "regProgress.emailVerification",
          "valid": false,
          "userResponse": original.trim(),
          "blocked": true,
          "message": isSpanish
              ? "⚠️ Tu correo ya ha sido verificado. No puedes reenviar otro código."
              : "⚠️ Your email has already been verified. You cannot resend another code.",
        };
      }

      // Detectar si el usuario quiere cambiar correo
      if (normalized.contains('cambiar correo') ||
          normalized.contains('change email') ||
          normalized.contains('different email') ||
          normalized.contains('otro correo')) {
        return {
          "step": "regProgress.emailVerification",
          "valid": false,
          "userResponse": original.trim(),
          "blocked": true,
          "message": isSpanish
              ? "⚠️ Tu correo ya ha sido verificado. No puedes cambiarlo de nuevo."
              : "⚠️ Your email has already been verified. You cannot change it again.",
        };
      }
    }

    // Detectar si el usuario quiere reenviar código (si aún NO está verificado)
    if (normalized.contains('reenviar') ||
        normalized.contains('resend') ||
        normalized.contains('send again') ||
        normalized.contains('enviar de nuevo')) {
      return {
        "step": "regProgress.emailVerification",
        "valid": true,
        "userResponse": "resendCode",
        "resendCode": true,
      };
    }

    // Detectar si el usuario quiere cambiar correo (si aún NO está verificado)
    if (normalized.contains('cambiar correo') ||
        normalized.contains('change email') ||
        normalized.contains('different email') ||
        normalized.contains('otro correo')) {
      return {
        "step": "regProgress.emailVerification",
        "valid": true,
        "userResponse": "changeEmail",
        "changeEmailFromOTP": true,
      };
    }

    // Validar código OTP (solo números, al menos 4 dígitos)
    if (RegExp(r'^\d{4,}$').hasMatch(original.trim())) {
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
      if (platform.isEmpty) continue;

      // Custom links use flat schema and don't provide profile pictures.
      final type = platform['type']?.toString().toLowerCase();
      if (type == 'custom') continue;

      // Expected schema for social networks: {'instagram': {...}}, {'twitter': {...}}, etc.
      // Be defensive in case maps contain unexpected extra keys.
      MapEntry<dynamic, dynamic>? firstMapEntry;
      for (final entry in platform.entries) {
        if (entry.value is Map) {
          firstMapEntry = entry;
          break;
        }
      }
      if (firstMapEntry == null) continue;

      final key = firstMapEntry.key.toString();
      final raw = firstMapEntry.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);

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

  /// Process a single option (from list_questions). This returns an AssistantResult
  /// that the UI (ia_chat_screen) will interpret and execute.
  /// - `option` can be either a String or a Map with keys "label" and/or "action".
  static AssistantResult handleSuggestion(dynamic option) {
    try {
      if (option == null) return AssistantResult.unknown();

      String? action;
      String? label;

      if (option is String) {
        label = option;
      } else if (option is Map<String, dynamic>) {
        label = (option['label'] as String?) ?? (option['text'] as String?);
        action = option['action'] as String?;
      } else if (option is Map<String, String>) {
        label = option['label'];
        action = option['action'];
      }

      // Use explicit action first (recommended)
      switch (action) {
        case 'open_camera':
          return AssistantResult.openCamera();
        case 'open_gallery':
          return AssistantResult.openGallery();
        case 'open_recorder':
          return AssistantResult.openRecorder();
        case 'skip':
          return AssistantResult.skip();
      }

      // Fallback: try to infer from label (only as last resort)
      final normalized = (label ?? '').toLowerCase();
      if (normalized.contains('camera') ||
          normalized.contains('take photo') ||
          normalized.contains('tomar foto')) {
        return AssistantResult.openCamera();
      }
      if (normalized.contains('gallery') ||
          normalized.contains('choose') ||
          normalized.contains('galería')) {
        return AssistantResult.openGallery();
      }
      if (normalized.contains('recorder') ||
          normalized.contains('audio') ||
          normalized.contains('grabar')) {
        return AssistantResult.openRecorder();
      }
      if (normalized.contains('skip') || normalized.contains('saltar')) {
        return AssistantResult.skip();
      }

      // Default: send label as text
      if ((label ?? '').isNotEmpty) {
        return AssistantResult.sendText(label!);
      }

      return AssistantResult.unknown();
    } catch (e, st) {
      debugPrint('assistant_functions.handleSuggestion error: $e\n$st');
      return AssistantResult.unknown();
    }
  }

  /// Detecta si el usuario está haciendo una pregunta "Why/Por qué/Para qué"
  /// Válido para cualquier idioma
  /// Más robusto: normaliza espacios, signos y acentos
  /// Maneja variaciones incompletas como "para qu" (sin la 'e' final)
  static bool _isWhyQuestion(String normalized, bool isSpanish) {
    // Normalizar: remover espacios extras, acentos y signos de puntuación
    final clean = normalized
        .replaceAll(RegExp(r'\s+'), ' ') // Múltiples espacios a uno
        .replaceAll(RegExp(r'[¿?!¡]'), '') // Remover signos de puntuación
        .replaceAll(RegExp(r'[áàä]'), 'a') // Normalizar acentos
        .replaceAll(RegExp(r'[éè]'), 'e')
        .replaceAll(RegExp(r'[í]'), 'i')
        .replaceAll(RegExp(r'[ó]'), 'o')
        .replaceAll(RegExp(r'[ú]'), 'u')
        .trim()
        .toLowerCase();

    // Patrones en inglés
    if (clean == 'why' ||
        clean.startsWith('why ') ||
        clean.endsWith(' why') ||
        clean.contains(' why ') ||
        clean.startsWith('why')) {
      return true;
    }

    // Patrones en español - MÚLTIPLES VARIACIONES
    // Detecta: "por qué", "por que", "porqué", "porque"
    // También: "para qué", "para que", "paraque"
    // Y variaciones incompletas: "por qu", "para qu", etc.
    if (
    // Variaciones completas
    clean.contains('por que') ||
        clean.contains('para que') ||
        clean.contains('porque') ||
        clean.contains('porqu') || // "porqué", "porque", "porqu?"
        clean.contains('paraq') || // "paraqué", "paraque", "paraq?"
        // Patrones de inicio
        clean.startsWith('por q') ||
        clean.startsWith('para q') ||
        clean.startsWith('que') ||
        // Exactos
        clean == 'por que' ||
        clean == 'para que' ||
        clean == 'porque' ||
        clean == 'porqu' ||
        clean == 'paraq') {
      return true;
    }

    return false;
  }

  /// Genera sugerencias dinámicas de nombre de usuario basadas en el nombre completo
  /// Genera 3 variantes sin mayúsculas, pegadas, con números
  /// Ejemplo: "Juan Esteban Arenilla Buendía" -> ["jeab12", "juanesteban", "juan031"]
  static List<String> generateUsernameSuggestions(String fullName) {
    if (fullName.trim().isEmpty) return [];

    // Limpiar y normalizar el nombre (remover acentos)
    final cleanName = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .trim();

    // Extraer palabras
    final words = cleanName.split(RegExp(r'\s+'));
    final suggestions = <String>[];

    // Sugerencia 1: Primeras letras + número aleatorio (ejemplo: jeab12)
    if (words.isNotEmpty && words.length >= 2) {
      final initials = words.map((w) => w[0]).join('');
      final randomNum = (DateTime.now().millisecond % 100).toString().padLeft(
        2,
        '0',
      );
      suggestions.add('$initials$randomNum');
    }

    // Sugerencia 2: Primeras dos palabras pegadas (ejemplo: juanesteban)
    if (words.isNotEmpty && words.length >= 2) {
      final combined = words.sublist(0, 2).join('');
      if (combined.length >= 3) {
        suggestions.add(combined);
      }
    }

    // Sugerencia 3: Primera palabra + número (ejemplo: juan031)
    if (words.isNotEmpty) {
      final firstName = words[0];
      final randomNum = (DateTime.now().millisecond % 1000).toString().padLeft(
        3,
        '0',
      );
      suggestions.add('$firstName$randomNum');
    }

    // Si no hay suficientes sugerencias únicas, generar más
    while (suggestions.length < 3 && words.isNotEmpty) {
      final randomNum = (DateTime.now().millisecond % 10000).toString();
      final suggestion = '${words.join('')}${randomNum.substring(0, 2)}';
      if (!suggestions.contains(suggestion)) {
        suggestions.add(suggestion);
      }
    }

    return suggestions.take(3).toList();
  }
}

/// High-level actions emitted by assistant when a suggestion is chosen.
enum AssistantAction {
  openCamera,
  openGallery,
  openRecorder,
  sendText,
  skip,
  unknown,
}

/// Wrapper result for suggestion handling.
class AssistantResult {
  final AssistantAction action;
  final String? payload;

  AssistantResult(this.action, {this.payload});

  factory AssistantResult.openCamera() =>
      AssistantResult(AssistantAction.openCamera);
  factory AssistantResult.openGallery() =>
      AssistantResult(AssistantAction.openGallery);
  factory AssistantResult.openRecorder() =>
      AssistantResult(AssistantAction.openRecorder);
  factory AssistantResult.sendText(String text) =>
      AssistantResult(AssistantAction.sendText, payload: text);
  factory AssistantResult.skip() => AssistantResult(AssistantAction.skip);
  factory AssistantResult.unknown() => AssistantResult(AssistantAction.unknown);
}
