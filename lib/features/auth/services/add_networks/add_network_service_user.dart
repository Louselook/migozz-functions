// add_network_service_user.dart
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

    // ✅ FIX: YouTube usa 'query', las demás usan 'username_or_link'
    final queryParamName = network.toLowerCase() == 'youtube'
        ? 'query'
        : 'username_or_link';

    final uri = Uri.parse(
      '${ApiConfig.apiBase}$endpoint',
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
      default:
        throw Exception('Red social no soportada para scraping: $network');
    }
  }

  // Métodos específicos
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
}
