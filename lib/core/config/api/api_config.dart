import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // URL de tu backend (Render u otro server)
  static final String apiBase = dotenv.env['API_GOLD'] ?? '';
}