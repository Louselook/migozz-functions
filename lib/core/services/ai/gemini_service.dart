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

    // Aseguramos sesión activa
    _session ??= _model!.startChat();

    try {
      final prompt =
          '${_systemPrompt()}\n${_stateSummary(state, stepIndex, lastUserMessage)}';
      final resp = await _session!.sendMessage(Content.text(prompt));
      final raw = resp.text?.trim();
      if (raw == null || raw.isEmpty) return null;

      // Normalize (strip Markdown/code fences) before parsing
      final text = _stripCodeFences(raw);

      // Expect a JSON-like block in response. Try to parse lightly.
      final parsed = _parseToMap(text) ?? _parseToMap(raw);
      if (parsed == null) return {'text': raw, 'options': <String>[]};
      return _withDefaults(parsed);
    } catch (e) {
      if (kDebugMode) debugPrint('GeminiService error: $e');
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
      ' Always answer in Spanish if the selected language is Spanish, otherwise in English.'
      ' You must return ONLY a compact JSON object with keys: text (string), options (array of strings, may be empty),'
      ' keyboardType ("text"|"number"), action (number, optional), dinamicResponse (string, optional).'
      ' Use short, friendly, and intuitive sentences tailored to the current step.'
      ' Avoid technical jargon; guide the user with clear next actions.'
      ' Do not include Markdown or extra commentary, and NEVER wrap the JSON in code fences (no ```json).'
      ' Strict JSON: use commas "," between fields and never use semicolons ";".'
      ' Return a single JSON object only.'
      ' The flow collects: email, language, fullName, username, gender, location, socialEcosystem (list of strings), avatarUrl, phone, voiceNoteUrl, category (list of strings), interests (map category->list).'
      ' Keep one question at a time and suggest options when appropriate.'
      ' VERY IMPORTANT: Use the "Current step index" provided to decide the next prompt according to this plan:'
      ' [1 language] ask preferred language with options ["Español","English"];'
      ' [2 fullName] ask for full name;'
      ' [3 username] ask for username;'
      ' [4 gender] ask for gender with options ["Hombre","Mujer"] in Spanish or ["Man","Woman"] in English;'
      ' [5 social action] ask to add social platforms and set {"action":0};'
      ' [6 social summary] acknowledge connected platforms and set {"dinamicResponse":"SocialEcosystemStep"};'
      ' [7 location confirm] confirm detected location with options ["Sí","No"] or ["Yes","No"];'
      ' [8 email confirm] confirm email with options ["Sí","No"] or ["Yes","No"]; if user said yes previously, the app will send OTP;'
      ' [9 OTP] ask the user to enter the OTP code (keyboardType="number");'
      ' [10 activated] congratulate and set {"dinamicResponse":"FollowedMessages"};'
      ' [11 avatar intro] introduce profile picture;'
      ' [12 avatar options] propose using social media photo or uploading new one;'
      ' [13 avatar choose] ask which one to use (the app may open uploader on user action);'
      '     If Instagram is connected and has a profile picture, suggest using it as default.'
      ' [14 phone] ask phone number (keyboardType="number");'
      ' [15 voice note] ask to record a short voice note;'
      ' [16 category action] ask to choose categories and set {"action":1};'
      ' [17 interests action] ask to choose interests and set {"action":2};'
      ' [18 finishing] say a short message like "Thanks! We are completing your registration.";'
      ' [19 complete] say registration is complete and welcome the user.'
      ' After step 19 the app will navigate to the profile screen.'
      ' Always keep responses short and friendly.'
      ' If the last user message is a clarifying question (e.g., "¿para qué es?", "what is it?"), first provide a brief explanation (max 2 lines) and then immediately continue with the relevant registration question for the current step.'
      ' Always keep the answer inside the JSON as the value of "text" and preserve the appropriate "keyboardType", "options", and optional "action"/"dinamicResponse".'
      ' When asking for OTP code or phone, set keyboardType to "number".'
      ' If you need to trigger navigation to the social ecosystem step, set {"action":0}.'
      ' If you want to follow with a special sequence after activation, set {"dinamicResponse":"FollowedMessages"}.';

  String _stateSummary(RegisterState s, int step, String? lastUser) {
    final lang = s.language ?? 'auto';
    final loc = s.location != null
        ? '${s.location!.city}, ${s.location!.country}'
        : 'unknown';
    final socials = s.socialEcosystem?.join(', ') ?? '';
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
      'avatarUrl=${s.avatarUrl}',
      'phone=${s.phone}',
      'voiceNoteUrl=${s.voiceNoteUrl}',
      'category=${s.category}',
      'interests=${s.interests}',
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
