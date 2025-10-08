import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:migozz_app/core/services/ai/rules.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';

class GeminiService {
  GeminiService._private();
  static final GeminiService instance = GeminiService._private();

  late GenerativeModel _model;
  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  // Mantener último json del bot y último input del usuario para confirmaciones.
  Map<String, dynamic>? _lastBotJson;
  String? _lastUserInput;

  // --------------------------------------------------------------------------
  // CONFIGURACIÓN DEL MODELO
  // --------------------------------------------------------------------------
  void ensureConfigured() {
    if (_isConfigured) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.trim().isEmpty) {
      debugPrint('❌ [GeminiService] API key no configurada.');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.12,
          maxOutputTokens: 300,
        ),
      );
      _isConfigured = true;
      debugPrint('✅ [GeminiService] Configurado correctamente.');
    } catch (e, st) {
      debugPrint('❌ [GeminiService] Error al configurar: $e\n$st');
    }
  }

  // --------------------------------------------------------------------------
  // REINICIO DE SESIÓN
  // --------------------------------------------------------------------------
  void resetSession() {
    _lastBotJson = null;
    _lastUserInput = null;
    debugPrint('♻️ [GeminiService] Sesión reiniciada.');
  }

  // --------------------------------------------------------------------------
  // ENTRADA DEL USUARIO
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>?> handleUserInput({
    required RegisterCubit cubit,
    required String userInput,
  }) async {
    final before = cubit.state;

    // Guardamos los "previos" para la lógica de confirmación
    final prevBot = _lastBotJson;
    final prevUser = _lastUserInput;

    final response = await nextBotTurn(
      state: before,
      lastUserMessage: userInput,
    );

    if (response == null) {
      debugPrint('⚠️ [Gemini] No hubo respuesta o error de parseo.');
      return null;
    }

    final isValid = response["valid"] == true;

    // Aplicamos transición usando prevBot/prevUser para casos de confirmación
    if (isValid) {
      _applyStateTransition(
        cubit: cubit,
        userInput: userInput,
        response: response,
        previousBotJson: prevBot,
        previousUserInput: prevUser,
      );
    }

    // Actualizamos el contexto histórico (después de aplicar la transición)
    _lastBotJson = response.cast<String, dynamic>();
    _lastUserInput = userInput;

    // --- BLOQUE DE DEBUG ÚNICO ---
    final after = cubit.state;
    debugPrint('''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 [STATE DEBUG]
👤 Usuario: "$userInput"
📍 Paso actual antes: ${before.regProgress.name}
📍 Paso actual después: ${after.regProgress.name}

💾 Estado ANTES:
${jsonEncode({"language": before.language, "fullName": before.fullName, "username": before.username, "gender": before.gender, "socialEcosystem": before.socialEcosystem})}

🤖 Respuesta del modelo:
${jsonEncode(response)}

💾 Estado DESPUÉS:
${jsonEncode({"language": after.language, "fullName": after.fullName, "username": after.username, "gender": after.gender, "socialEcosystem": after.socialEcosystem})}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');

    return response;
  }

  // --------------------------------------------------------------------------
  // LLAMADA A GEMINI
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>?> nextBotTurn({
    required RegisterState state,
    String? lastUserMessage,
  }) async {
    if (!_isConfigured) {
      debugPrint('⚠️ [Gemini] No configurado.');
      return null;
    }

    final prompt = _buildPrompt(state, lastUserMessage);

    try {
      final resp = await _model.generateContent([Content.text(prompt)]);
      final text = resp.text?.trim() ?? '';
      // dentro de nextBotTurn después de obtener `json`
      final json = _extractJson(text);
      if (json == null) {
        debugPrint('⚠️ [Gemini] No se pudo parsear JSON.');
        return null;
      }

      // Validación mínima y normalización
      if (!(json.containsKey('text') && (json['text'] is String))) {
        debugPrint('⚠️ [Gemini] JSON inválido: falta "text" o no es String.');
        return null;
      }
      if (!(json.containsKey('valid') && (json['valid'] is bool))) {
        debugPrint('⚠️ [Gemini] JSON inválido: falta "valid" o no es bool.');
        return null;
      }

      // Normalizar opciones
      final options = (json['options'] is List)
          ? List<String>.from(json['options'].map((e) => e.toString()))
          : <String>[];
      final keyboardType = (json['keyboardType'] is String)
          ? json['keyboardType'] as String
          : 'text';
      final action = json['action'];

      final extractedVal = json['extracted'] ?? json['extradet'];
      return {
        "text": json["text"] ?? "⚠️ Respuesta vacía",
        "options": options,
        "keyboardType": keyboardType,
        "valid": json["valid"] ?? false,
        "action": action,
        "extracted": (extractedVal is String && extractedVal.trim().isNotEmpty)
            ? extractedVal.trim()
            : null,
        "call": json["call"],
      };
    } catch (e, st) {
      debugPrint('❌ [Gemini] Error en nextBotTurn(): $e\n$st');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CAMBIO DE ESTADO DEL CUBIT
  // ahora acepta previousBotJson y previousUserInput para casos de confirmación
  // --------------------------------------------------------------------------
  void _applyStateTransition({
    required RegisterCubit cubit,
    required String userInput,
    required Map<String, dynamic> response,
    Map<String, dynamic>? previousBotJson,
    String? previousUserInput,
  }) {
    final step = cubit.state.regProgress;
    final isValid = response["valid"] == true;
    if (!isValid) return;

    String? extracted = (response['extracted'] is String)
        ? (response['extracted'] as String).trim()
        : null;

    // si el usuario dijo "sí" intentamos recuperar extracted de previousBotJson
    if (extracted == null && _isAffirmative(userInput)) {
      if (previousBotJson != null &&
          previousBotJson['extracted'] is String &&
          (previousBotJson['extracted'] as String).trim().isNotEmpty) {
        extracted = (previousBotJson['extracted'] as String).trim();
      } else if (previousUserInput != null) {
        extracted = _extractNameFromText(previousUserInput);
      }
    }

    // extraer desde el mismo userInput si es fullName y no hay extracted
    if (extracted == null && step == RegisterStatusProgress.fullName) {
      extracted = _extractNameFromText(userInput);
    }

    final valueToSave = extracted ?? userInput.trim();

    switch (step) {
      case RegisterStatusProgress.language:
        if (cubit.state.language == null) {
          final normalized = _inferLanguageFromText(valueToSave) ?? valueToSave;
          cubit.setLanguage(normalized);
        } else {
          debugPrint('⚠️ language ya estaba guardado, no sobreescribiendo.');
        }
        break;

      case RegisterStatusProgress.fullName:
        if (cubit.state.fullName == null) {
          // validar nombre: al menos 2 palabras y sin dígitos
          if (_extractNameFromText(valueToSave) != null) {
            cubit.setFullName(_extractNameFromText(valueToSave)!);
          } else {
            debugPrint('⚠️ fullName inválido, no guardado: $valueToSave');
          }
        }
        break;

      case RegisterStatusProgress.username:
        if (cubit.state.username == null) {
          if (_isValidUsername(valueToSave)) {
            cubit.setUsername(valueToSave);
          } else {
            debugPrint('⚠️ username inválido: $valueToSave');
          }
        }
        break;

      case RegisterStatusProgress.gender:
        if (cubit.state.gender == null) {
          final v = valueToSave.toLowerCase();
          if ([
            'hombre',
            'mujer',
            'otro',
            'male',
            'female',
            'other',
          ].contains(v)) {
            cubit.setGender(valueToSave);
          } else {
            debugPrint('⚠️ gender inválido: $valueToSave');
          }
        }
        break;

      case RegisterStatusProgress.socialEcosystem:
        // Este paso tratase fuera; por ahora no guardamos aquí automáticamente
        break;

      case RegisterStatusProgress.location:
        if (cubit.state.location == null) {
          debugPrint('⚠️ location no disponible para setear automáticamente.');
        } else {
          cubit.setVerifyLocation();
        }
        break;

      case RegisterStatusProgress.emailVerification:
        // No guardar aquí; la confirmación debe venir con call: sendEmailOtp
        break;

      default:
        debugPrint('⚠️ Paso no manejado: $step');
    }
  }

  // --------------------------------------------------------------------------
  // PROMPT PRINCIPAL
  // --------------------------------------------------------------------------
  // En gemini_service.dart - actualiza el método _buildPrompt

  String _buildPrompt(RegisterState state, String? lastUser) {
    final step = state.regProgress.name;

    String lang;
    if (step == 'language') {
      final inferred = _inferLanguageFromText(lastUser);
      lang = inferred ?? (state.language ?? 'English');
    } else {
      lang = state.language ?? 'English';
    }

    // 🔹 NUEVO: Formatear location para el prompt
    String locationInfo = "null";
    if (state.location != null) {
      final loc = state.location!;
      locationInfo = "${loc.city}, ${loc.state}, ${loc.country}";
    }

    // 🔹 NUEVO: Formatear socialEcosystem para el prompt
    String socialInfo = "null";
    if (state.socialEcosystem != null && state.socialEcosystem!.isNotEmpty) {
      final networks = state.socialEcosystem!
          .map((e) => e.keys.first)
          .join(', ');
      socialInfo =
          "[$networks] (${state.socialEcosystem!.length} red(es) vinculada(s))";
    }

    return '''
$rules

📍 ESTADO ACTUAL:
- Paso: "$step"
- Idioma: "$lang"
- Último mensaje del usuario: "${lastUser ?? "ninguno"}"

📊 DATOS GUARDADOS:
- email:  ${state.email ?? "null"}
- language: ${state.language ?? "null"}
- fullName: ${state.fullName ?? "null"}  
- username: ${state.username ?? "null"}
- gender: ${state.gender ?? "null"}
- socialEcosystem: $socialInfo
- location: $locationInfo
- emailVerification: ${state.emailVerification}
- phone: ${state.phone ?? "null"}
- avatarUrl: ${state.avatarUrl ?? "null"}
- category: ${state.category ?? "null"}
- interests: ${state.interests ?? "null"}

🎯 TU MISIÓN:
1) Solo preguntar el paso actual si el dato NO está guardado.
2) Si un campo ya tiene valor (no es "null"), NUNCA preguntes por él.
3) Si location ya está guardada, preguntar para confirmar.
4) Si socialEcosystem tiene redes, NO preguntes por redes sociales.
5) Validar la respuesta según el paso actual.
6) Generar JSON solo con: text, options, keyboardType, valid, action, extracted (cuando aplique).
7) Valid=true solo si la respuesta corresponde al paso actual.
8) Valid=false si la respuesta es ambigua, irrelevante, o ya guardada.

⚠️ REGLA CRÍTICA:
- Antes de preguntar por cualquier campo, verifica si ya tiene valor arriba en "DATOS GUARDADOS".
- Si el campo ya tiene valor, salta automáticamente al siguiente paso sin preguntar.
- Ejemplo: Si location = "Medellín, Antioquia, Colombia", NO preguntes por ubicación.

IMPORTANTE: Si el usuario indicó su idioma (por ej. "Español"), responde en ese idioma.
RESPONDE SOLO CON JSON.
''';
  }

  // --------------------------------------------------------------------------
  // DETECCIÓN DE IDIOMA (útil para normalizar language)
  // --------------------------------------------------------------------------
  String? _inferLanguageFromText(String? text) {
    if (text == null) return null;
    final t = text.trim().toLowerCase();

    final spanishPattern = RegExp(
      r'\b(español|esp|espanol|spanish|es)\b',
      caseSensitive: false,
    );
    final englishPattern = RegExp(
      r'\b(english|inglés|ingles|en)\b',
      caseSensitive: false,
    );

    if (spanishPattern.hasMatch(t)) return 'Español';
    if (englishPattern.hasMatch(t)) return 'English';
    return null;
  }

  // --------------------------------------------------------------------------
  // AYUDAS: detectar afirmativo y extraer nombre simple
  // --------------------------------------------------------------------------
  bool _isAffirmative(String? s) {
    if (s == null) return false;
    final t = s.trim().toLowerCase();
    // patrones cortos o frases que comienzan con afirmación
    final pattern = RegExp(
      r'^(sí|si|s|yes|y|claro|correcto|confirmo|affirmative|ok|vale)\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(t);
  }

  String? _extractNameFromText(String text) {
    var t = text.trim();
    // eliminar frases tipo "mi nombre es", "me llamo", "soy"
    t = t.replaceFirst(
      RegExp(r'^(mi nombre es|me llamo|soy)\s*[:\-]?\s*', caseSensitive: false),
      '',
    );
    // eliminar caracteres raros
    t = t.replaceAll(RegExp(r'[^\w\sáéíóúÁÉÍÓÚñÑ]'), '').trim();
    if (t.isEmpty) return null;
    final words = t.split(RegExp(r'\s+'));
    if (words.length >= 2 && !RegExp(r'\d').hasMatch(t)) {
      // capitalizar cada palabra
      final normalized = words
          .map(
            (w) => w.isEmpty
                ? w
                : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')),
          )
          .join(' ');
      return normalized;
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // PARSEO JSON FLEXIBLE
  // --------------------------------------------------------------------------
  // PARSEO JSON FLEXIBLE - versión mejorada
  Map<String, dynamic>? _extractJson(String text) {
    try {
      if (text.trim().isEmpty) return null;

      // intenta encontrar el bloque {...} más grande
      final first = text.indexOf('{');
      final last = text.lastIndexOf('}');
      if (first == -1 || last == -1 || last <= first) return null;

      var jsonStr = text.substring(first, last + 1);

      // normalizar comillas simples a dobles (cuidado con apostrofes en texto, intentamos solo si parece JSON)
      // solo si hay comillas simples sin muchas comillas dobles
      if ((jsonStr.contains("'") && !jsonStr.contains('"')) ||
          (jsonStr.split('"').length < jsonStr.split("'").length)) {
        jsonStr = jsonStr.replaceAll("'", '"');
      }

      // eliminar // comments y /* */ (por si)
      jsonStr = jsonStr.replaceAll(RegExp(r'//.*?\n'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

      // quitar comas finales antes de cierres }
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*\]'), ']');

      final parsed = jsonDecode(jsonStr);

      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is List && parsed.isNotEmpty && parsed[0] is Map) {
        return Map<String, dynamic>.from(parsed[0]);
      }
      return null;
    } catch (e, st) {
      debugPrint('⚠️ [Gemini] Error parseando JSON: $e\n$st');
      return null;
    }
  }

  bool _isValidUsername(String? username) {
    if (username == null) return false;
    final u = username.trim();
    // 3-20 chars, letras, números, guión bajo y punto permitido
    return RegExp(r'^[a-zA-Z0-9._]{3,20}$').hasMatch(u);
  }
}
