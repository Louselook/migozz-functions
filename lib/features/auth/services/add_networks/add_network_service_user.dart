import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';

class AddNetworkServiceUser {
  /// Método genérico para obtener perfil por username/link
  Future<Map<String, dynamic>> getProfileByUsernameOrLink({
    required String network,
    required String usernameOrLink,
  }) async {
    final endpoint = _getProfileEndpoint(network);

    // ✅ Decidir qué API usar según la red social
    final String? baseUrl = _getApiBaseForNetwork(network);

    if (baseUrl == null) {
      throw Exception('No hay API configurada para $network');
    }

    // ✅ YouTube usa 'query', las demás usan 'username_or_link'
    final queryParamName = network.toLowerCase() == 'youtube'
        ? 'query'
        : 'username_or_link';

    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: {queryParamName: usernameOrLink});

    debugPrint('🔍 [$network] Fetching profile: $usernameOrLink');
    debugPrint('🔍 URL: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [$network] Profile fetched successfully');
        return data;
      } else {
        debugPrint('❌ [$network] Error: ${response.body}');
        throw Exception('Error fetching $network profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [$network] Exception: $e');
      rethrow;
    }
  }

  /// ✅ ACTUALIZADO: Decidir qué API usar según la red social
  String? _getApiBaseForNetwork(String network) {
    switch (network.toLowerCase()) {
      // Usar Cloud Run Functions (scraper con Puppeteer)
      case 'tiktok':
      case 'facebook':
      case 'twitch':
      case 'kick':
        // case 'trovo':
        return ApiConfig.apiFuctions;

      // Usar API principal (tiene YouTube, Instagram OAuth, LinkedIn OAuth, etc.)
      case 'youtube':
      case 'instagram':
      case 'linkedin':
      case 'twitter':
      case 'spotify':
        return ApiConfig.apiBase;

      default:
        return null;
    }
  }

  /// Obtener el endpoint correcto según la red social
  String _getProfileEndpoint(String network) {
    switch (network.toLowerCase()) {
      case 'youtube':
        return '/youtube/channel';
      case 'instagram':
        return '/instagram/profile';
      case 'tiktok':
        return '/tiktok/profile';
      case 'linkedin':
        return '/linkedin/profile';
      case 'twitter':
        return '/twitter/profile';
      case 'facebook':
        return '/facebook/profile';
      case 'spotify':
        return '/spotify/profile';
      case 'twitch':
        return '/twitch/profile';
      case 'kick': // ✅ NUEVO
        return '/kick/profile';
      // case 'trovo':
      //   return '/trovo/profile';
      default:
        throw Exception('Red social no soportada: $network');
    }
  }

  // ==================== MÉTODOS ESPECÍFICOS ====================

  Future<Map<String, dynamic>> getYouTubeProfile(String handleOrUrl) =>
      getProfileByUsernameOrLink(
        network: 'youtube',
        usernameOrLink: handleOrUrl,
      );

  Future<Map<String, dynamic>> getInstagramProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'instagram',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getTikTokProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'tiktok',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getLinkedInProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'linkedin',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getFacebookProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'facebook',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getTwitterProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'twitter',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getTwitchProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'twitch',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getKickProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'kick',
        usernameOrLink: usernameOrLink,
      );

  // // ✅ NUEVO: Trovo (opcional)
  // Future<Map<String, dynamic>> getTrovoProfile(String usernameOrLink) =>
  //     getProfileByUsernameOrLink(
  //       network: 'trovo',
  //       usernameOrLink: usernameOrLink,
  //     );
}
