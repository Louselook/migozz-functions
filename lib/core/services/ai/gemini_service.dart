import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  ChatSession? _session;
  String _modelName = 'gemini-2.0-flash';
  bool _triedFallback = false;

  // --- Concurrency & duplicate guards ---
  bool _inFlight = false;
  int? _lastStepResponded;
  String? _lastResponseHash;
  DateTime? _lastStepTimestamp;

  bool get isConfigured => _model != null;

  void ensureConfigured() {
    if (_model != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'GeminiService: GEMINI_API_KEY missing, running in fallback.',
        );
      }
      return;
    }
    _configureModel(apiKey, _modelName);
    // crear sesión de chat (memoria)
    _session = _model!.startChat();
  }

  void _configureModel(String apiKey, String modelName) {
    _model = GenerativeModel(model: modelName, apiKey: apiKey);
  }

  /// Permite refrescar la API Key en caliente (por rotación de credenciales)
  Future<bool> refreshApiKey({String? newKey, String? newModel}) async {
    final key = newKey ?? dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      if (kDebugMode) debugPrint('GeminiService.refreshApiKey: key vacía');
      return false;
    }
    _modelName = newModel ?? _modelName;
    _configureModel(key, _modelName);
    resetSession();
    if (kDebugMode)
      debugPrint('GeminiService: API key refrescada, modelo=$_modelName');
    return true;
  }

  /// Reinicia la memoria de la sesión (nuevo registro)
  void resetSession() {
    if (_model == null) return;
    _session = _model!.startChat();
  }

  Future<Map<String, dynamic>?> nextBotTurn({
    required RegisterState state,
    required int stepIndex,
    String? lastUserMessage,
    List<Map<String, dynamic>>? previousMessages,
  }) async {
    ensureConfigured();
    if (_model == null) return null; // fallback to scripted flow

    // Validate step range (1..19); silently ignore if out-of-range
    if (stepIndex < 1 || stepIndex > 19) {
      if (kDebugMode) {
        debugPrint('GeminiService: Ignoring out-of-range stepIndex=$stepIndex');
      }
      return null;
    }

    // Concurrency lock
    if (_inFlight) {
      if (kDebugMode) debugPrint('GeminiService: in-flight request skipped');
      return null;
    }
    _inFlight = true;

    // Throttle duplicate rapid calls for same step (<700ms)
    final now = DateTime.now();
    if (_lastStepResponded == stepIndex &&
        _lastStepTimestamp != null &&
        now.difference(_lastStepTimestamp!) <
            const Duration(milliseconds: 700)) {
      _inFlight = false;
      if (kDebugMode) {
        debugPrint('GeminiService: throttled duplicate step=$stepIndex');
      }
      return null;
    }

    // Aseguramos sesión activa
    _session ??= _model!.startChat();

    try {
      final prompt =
          '${_systemPrompt()}\n${_stateSummary(state, stepIndex, lastUserMessage)}';
      final resp = await _session!.sendMessage(Content.text(prompt));
      final raw = resp.text?.trim();
      if (raw == null || raw.isEmpty) {
        _inFlight = false;
        return null;
      }

      // Normalize (strip Markdown/code fences) before parsing
      final text = _stripCodeFences(raw);

      // Expect a JSON-like block in response. Try to parse lightly.
      final parsed = _parseToMap(text) ?? _parseToMap(raw);
      final result = _withDefaults(
        parsed ?? {'text': raw, 'options': <String>[]},
      );

      // Duplicate textual response filter
      final hash = result['text'].hashCode.toString();
      if (_lastResponseHash == hash && _lastStepResponded == stepIndex) {
        if (kDebugMode) {
          debugPrint('GeminiService: filtered duplicate response');
        }
        _inFlight = false;
        return null;
      }

      _lastResponseHash = hash;
      _lastStepResponded = stepIndex;
      _lastStepTimestamp = now;
      _inFlight = false;
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('GeminiService error: $e');
      _inFlight = false;
      // Fallback de modelo si falla (p.ej., modelo no disponible)
      if (!_triedFallback) {
        _triedFallback = true;
        try {
          final apiKey = dotenv.env['GEMINI_API_KEY'];
          if (apiKey != null && apiKey.isNotEmpty) {
            _modelName = 'gemini-1.5-flash';
            _configureModel(apiKey, _modelName);
            resetSession();
            // reintento una vez
            final prompt =
                '${_systemPrompt()}\n${_stateSummary(state, stepIndex, lastUserMessage)}';
            final resp = await _session!.sendMessage(Content.text(prompt));
            final raw = resp.text?.trim();
            if (raw == null || raw.isEmpty) return null;
            final text = _stripCodeFences(raw);
            final parsed = _parseToMap(text) ?? _parseToMap(raw);
            if (parsed == null) return {'text': raw, 'options': <String>[]};
            return _withDefaults(parsed);
          }
        } catch (e2) {
          if (kDebugMode) debugPrint('Gemini fallback error: $e2');
        }
      }
      return null;
    }
  }

  String _systemPrompt() =>
      'You are an assistant that drives a registration chat wizard.'
      ' Output policy: Return ONLY one compact JSON object. No markdown, no backticks, no commentary.'
      ' Keys: text (string), options (array<string>), keyboardType ("text"|"number"), optional action (int), optional dinamicResponse (string).'
      ' Language: If selected language is Spanish, respond in Spanish; else respond in English.'
      ' HARD CONSTRAINTS:'
      ' 1) Never mention or hint future steps beyond the current step index.'
      ' 2) Do NOT mention avatar/photo before steps 11-13.'
      ' 3) Do NOT mention location before step 7.'
      ' 4) Do NOT mention email confirmation before step 8.'
      ' 5) Do NOT ask for OTP before step 9.'
      ' 6) Exactly one concise question or confirmation per response.'
      ' 7) If user asked a clarifying question, prepend <=2 short explanatory sentences then append the proper step question in same "text".'
      ' 8) If Instagram is connected and step is 11-13 you may suggest using that photo politely once.'
      ' 9) For OTP or phone set keyboardType="number".'
      ' STEP PLAN:'
      ' [1 language] -> ask language with options ["Español","English"].'
      ' [2 fullName] -> ask full name.'
      ' [3 username] -> ask username.'
      ' [4 gender] -> ask gender with localized options.'
      ' [5 social action] -> ask to add platforms action=0.'
      ' [6 social summary] -> acknowledge connected platforms dinamicResponse=SocialEcosystemStep.'
      ' [7 location confirm] -> confirm location with Yes/No.'
      ' [8 email confirm] -> confirm email with Yes/No.'
      ' [9 OTP] -> request OTP code.'
      ' [10 activated] -> congratulate dinamicResponse=FollowedMessages.'
      ' [11 avatar intro] -> introduce avatar step.'
      ' [12 avatar options] -> explain options.'
      ' [13 avatar choose] -> ask which to use.'
      ' [14 phone] -> ask phone.'
      ' [15 voice note] -> ask for short voice note.'
      ' [16 category action] -> ask choose categories action=1.'
      ' [17 interests action] -> ask choose interests action=2.'
      ' [18 finishing] -> short finishing message.'
      ' [19 complete] -> final welcome.'
      ' Avatar & Anti-Repetition Rules (DO NOT break these):'
      ' 1) Avatar steps are ONLY 11, 12, 13. Outside these steps NEVER mention photo, avatar, picture or image sources.'
      ' 2) Step 11: single short intro sentence; options empty.'
      ' 3) Step 12: options list = connected platform names WITH an image (exact capitalization) + final option (Spanish:"Subir foto" English:"Upload photo"). If no platforms: only that upload option.'
      ' 4) Step 13: if user chooses a valid platform name or upload option, give ONE concise confirmation; no options; never restate the list. If invalid platform, brief correction + list once.'
      ' 5) After successful confirmation in step 13 never mention avatar again.'
      ' 6) Never repeat the exact same question consecutively; keep short memory to avoid loops.'
      ' 7) If user repeats already confirmed choice, acknowledge briefly (<=10 words) without options.'
      ' 8) Clarifying question during steps 11-13: <=2 brief explanatory sentences + proper step behavior (no duplication).'
      ' 9) No invented platforms; only those given. If none: just upload option.'
      ' 10) Avoid repeating identical emoji sequences in consecutive steps.'
      ' JSON ONLY.';

  String _stateSummary(RegisterState s, int step, String? lastUser) {
    final lang = s.language ?? 'auto';
    final loc = s.location != null
        ? '${s.location!.city}, ${s.location!.country}'
        : 'unknown';
    final socials =
        s.socialEcosystem?.map((e) => e.keys.first).join(', ') ?? '';
    // Mask future fields so model doesn't jump ahead
    String? avatarMasked = step >= 11 ? s.avatarUrl : null;
    String? phoneMasked = step >= 14 ? s.phone : null;
    String? voiceMasked = step >= 15 ? s.voiceNoteUrl : null;
    List<String>? categoryMasked = step >= 16 ? s.category : null;
    Map<String, List<String>>? interestsMasked = step >= 17
        ? s.interests
        : null;
    return [
      'Current step index: $step',
      'Selected language: $lang',
      'Known values:',
      'fullName=${s.fullName}',
      'username=${s.username}',
      'gender=${s.gender}',
      'email=${s.email}',
      'location=$loc',
      'socialEcosystem=$socials',
      'avatarUrl=$avatarMasked',
      'phone=$phoneMasked',
      'voiceNoteUrl=$voiceMasked',
      'category=$categoryMasked',
      'interests=$interestsMasked',
      if (lastUser != null) 'Last user message: $lastUser',
    ].join('\n');
  }

  Map<String, dynamic>? _parseToMap(String text) {
    // Try to find a JSON object in the text.
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    final jsonLike = text.substring(start, end + 1);
    return _looseJsonDecode(jsonLike);
  }

  Map<String, dynamic>? _looseJsonDecode(String s) {
    // Small fixers: normalize quotes, replace semicolons, remove trailing commas, collapse whitespace.
    String fixed = s
        .replaceAll(RegExp(r'\r?\n'), ' ')
        // smart quotes to plain
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"')
        .replaceAll('\u2018', '"')
        .replaceAll('\u2019', '"')
        // occasional single quotes
        .replaceAll(RegExp(r"'"), '"')
        // common mistake: semicolons between fields -> commas
        .replaceAll(RegExp(r';\s*\}'), '}')
        .replaceAll(RegExp(r';\s*\]'), ']')
        .replaceAll(RegExp(r';\s*"'), ',"')
        // remove trailing commas before } or ]
        .replaceAll(RegExp(r',\s*([}\]])'), r'$1')
        .trim();
    // convert any remaining "; key" into ",key"
    fixed = fixed.replaceAllMapped(
      RegExp(r';\s*([a-zA-Z0-9_])'),
      (m) => ',${m.group(1)}',
    );
    return _tryStrictJson(fixed);
  }

  Map<String, dynamic>? _tryStrictJson(String s) {
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) return obj;
      return null;
    } catch (_) {
      return null;
    }
  }

  // Strip Markdown code fences like ```json ... ```
  String _stripCodeFences(String s) {
    if (!s.contains('```')) return s;
    // Remove opening ```json or ``` and closing ```
    var out = s.replaceAll(RegExp(r"```[a-zA-Z]*"), '').replaceAll('```', '');
    return out.trim();
  }

  // Ensure required defaults for UI
  Map<String, dynamic> _withDefaults(Map<String, dynamic> m) {
    final out = Map<String, dynamic>.from(m);
    out['text'] = (out['text'] ?? '').toString();
    out['options'] = (out['options'] is List)
        ? List<String>.from(out['options'] as List)
        : <String>[];
    if (out['keyboardType'] != 'number') {
      out['keyboardType'] = 'text';
    }
    // Coerce action to int if present as string
    if (out.containsKey('action') && out['action'] is String) {
      final v = int.tryParse(out['action']);
      if (v != null) out['action'] = v;
    }
    return out;
  }
}
