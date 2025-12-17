import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';

class AddNetworkServiceUser {
  /// Método genérico para obtener perfil por username o link
  Future<Map<String, dynamic>> getProfileByUsernameOrLink({
    required String network,
    required String usernameOrLink,
  }) async {
    final networkKey = network.toLowerCase();

    final baseUrl = _getApiBaseForNetwork(networkKey);
    final endpoint = _getProfileEndpoint(networkKey);
    final queryParamName = _getQueryParamName(networkKey);

    if (baseUrl == null) {
      throw Exception('No hay API configurada para $network');
    }

    // Asegurarse del correcto formateo de la URL (concatenar base + endpoint)
    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: {queryParamName: usernameOrLink});

    debugPrint('🔍 [$network] Fetching profile');
    debugPrint('🔍 Base URL usada: $baseUrl'); // <-- ayuda a depurar
    debugPrint('🔍 URL: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [$network] Profile fetched successfully');
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ [$network] Error: ${response.body}');
        throw Exception('Error fetching $network profile');
      }
    } catch (e) {
      debugPrint('❌ [$network] Exception: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // API BASE POR RED (ahora instagram y linkedin usan apiBase; el resto apiFuctions)
  // ---------------------------------------------------------------------------
  String? _getApiBaseForNetwork(String network) {
    switch (network) {
      // Para estas redes queremos usar el backend principal (apiBase)
      case 'instagram':
      case 'linkedin':
        return ApiConfig.apiBase;

      // Resto: scrapers / funciones serverless
      case 'tiktok':
      case 'facebook':
      case 'twitch':
      case 'kick':
      case 'trovo':
      case 'reddit':
      case 'threads':
      case 'pinterest':
      case 'soundcloud':
      case 'applemusic':
      case 'deezer':
      case 'discord':
      case 'snapchat':
      case 'youtube':
      case 'twitter':
      case 'spotify':
        return ApiConfig.apiFuctions;

      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ENDPOINT POR RED
  // ---------------------------------------------------------------------------
  String _getProfileEndpoint(String network) {
    switch (network) {
      case 'youtube':
        return '/youtube/profile';
      case 'instagram':
        return '/instagram/profile';
      case 'linkedin':
        return '/linkedin/profile';
      case 'twitter':
        return '/twitter/profile';
      case 'spotify':
        return '/spotify/profile';
      case 'tiktok':
        return '/tiktok/profile';
      case 'facebook':
        return '/facebook/profile';
      case 'twitch':
        return '/twitch/profile';
      case 'kick':
        return '/kick/profile';
      case 'trovo':
        return '/trovo/profile';
      case 'reddit':
        return '/reddit/profile';
      case 'threads':
        return '/threads/profile';
      case 'pinterest':
        return '/pinterest/profile';
      case 'soundcloud':
        return '/soundcloud/profile';
      case 'applemusic':
        return '/applemusic/profile';
      case 'deezer':
        return '/deezer/profile';
      case 'discord':
        return '/discord/profile';
      case 'snapchat':
        return '/snapchat/profile';
      default:
        throw Exception('Red social no soportada: $network');
    }
  }

  // ---------------------------------------------------------------------------
  // QUERY PARAM POR RED
  // ---------------------------------------------------------------------------
  String _getQueryParamName(String network) {
    // youtube usa 'query' en tu backend; el resto usa 'username_or_link'
    if (network == 'youtube') return 'query';
    return 'username_or_link';
  }

  // ==================== MÉTODOS ESPECÍFICOS ====================

  Future<Map<String, dynamic>> getYouTubeProfile(String value) =>
      getProfileByUsernameOrLink(network: 'youtube', usernameOrLink: value);

  Future<Map<String, dynamic>> getInstagramProfile(String value) =>
      getProfileByUsernameOrLink(network: 'instagram', usernameOrLink: value);

  Future<Map<String, dynamic>> getLinkedInProfile(String value) =>
      getProfileByUsernameOrLink(network: 'linkedin', usernameOrLink: value);

  Future<Map<String, dynamic>> getTikTokProfile(String value) =>
      getProfileByUsernameOrLink(network: 'tiktok', usernameOrLink: value);

  Future<Map<String, dynamic>> getFacebookProfile(String value) =>
      getProfileByUsernameOrLink(network: 'facebook', usernameOrLink: value);

  Future<Map<String, dynamic>> getTwitterProfile(String value) =>
      getProfileByUsernameOrLink(network: 'twitter', usernameOrLink: value);

  Future<Map<String, dynamic>> getSpotifyProfile(String value) =>
      getProfileByUsernameOrLink(network: 'spotify', usernameOrLink: value);
}
