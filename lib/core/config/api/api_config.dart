import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper para obtener variables de entorno.
/// Prioriza --dart-define sobre .env
String? getEnvVar(String key) {
  final dartDefine = String.fromEnvironment(key, defaultValue: '');
  if (dartDefine.isNotEmpty) return dartDefine;
  return dotenv.env[key];
}

class ApiConfig {
  // URL de tu backend (Render u otro server)
  // Prioriza --dart-define, luego .env
  static final String? apiBase = getEnvVar('API_MIGOZZ');
  static final String? apiFuctions = getEnvVar('API_FUNCTIONS');
  static final String? googleClientId = getEnvVar('GOOGLE_CLIENT_ID');
}
