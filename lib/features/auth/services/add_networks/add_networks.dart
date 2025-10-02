import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';

class AddNetworkService {
  Future<ProfileData> getInstagramProfile({
    required String usernameOrLink,
  }) async {
    // Construir URI con query parameters
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/networks/add-instagram',
    ).replace(queryParameters: {'username_or_link': usernameOrLink});

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileData.fromJson(data); // ya incluye url
      } else if (response.statusCode == 404) {
        throw Exception('Perfil no encontrado: $usernameOrLink');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error obteniendo perfil de Instagram: $e');
    }
  }
}
