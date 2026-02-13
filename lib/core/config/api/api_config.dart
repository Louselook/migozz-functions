import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Constantes de compile-time desde --dart-define
const String _apiMigozzDefine = String.fromEnvironment('API_MIGOZZ');
const String _apiFunctionsDefine = String.fromEnvironment('API_FUNCTIONS');
const String _googleClientIdDefine = String.fromEnvironment('GOOGLE_CLIENT_ID');
const String _geminiApiKeyDefine = String.fromEnvironment('GEMINI_API_KEY');

/// Helper para obtener variables de entorno.
/// Prioriza --dart-define (compile-time) sobre .env (runtime)
String? getEnvVar(String key) {
  // Primero verificar valores de compile-time (--dart-define)
  switch (key) {
    case 'API_MIGOZZ':
      if (_apiMigozzDefine.isNotEmpty) return _apiMigozzDefine;
      break;
    case 'API_FUNCTIONS':
      if (_apiFunctionsDefine.isNotEmpty) return _apiFunctionsDefine;
      break;
    case 'GOOGLE_CLIENT_ID':
      if (_googleClientIdDefine.isNotEmpty) return _googleClientIdDefine;
      break;
    case 'GEMINI_API_KEY':
      if (_geminiApiKeyDefine.isNotEmpty) return _geminiApiKeyDefine;
      break;
  }
  // Fallback a .env (desarrollo local)
  return dotenv.env[key];
}

class ApiConfig {
  // URL de tu backend (Render u otro server)
  // Prioriza --dart-define, luego .env
  static final String? apiBase = getEnvVar('API_MIGOZZ');
  static final String? apiFuctions = getEnvVar('API_FUNCTIONS');
  static final String? googleClientId = getEnvVar('GOOGLE_CLIENT_ID');
}
