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

    // Decidir qué API usar según la red social (por defecto usamos apiFuctions que apunta a tu backend de scrapers)
    final String? baseUrl = _getApiBaseForNetwork(network);

    if (baseUrl == null) {
      throw Exception('No hay API configurada para $network');
    }

    // Tu backend usa siempre 'username_or_link' como query param
    final queryParamName = 'username_or_link';

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
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ [$network] Error: ${response.body}');
        throw Exception('Error fetching $network profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [$network] Exception: $e');
      rethrow;
    }
  }

  /// ACTUALIZADO: Decidir qué API usar según la red social
  /// Por ahora todas las plataformas de scraping apuntan a ApiConfig.apiFuctions.
  /// Si necesitas que alguna use ApiConfig.apiBase, cámbialo aquí.
  String? _getApiBaseForNetwork(String network) {
    switch (network.toLowerCase()) {
      case 'tiktok':
      case 'facebook':
      case 'twitch':
      case 'kick':
      case 'trovo':
      case 'youtube':
      case 'instagram':
      case 'linkedin':
      case 'twitter':
      case 'spotify':
      case 'reddit':
      case 'threads':
      case 'pinterest':
      case 'soundcloud':
      case 'applemusic':
      case 'deezer':
      case 'discord':
      case 'snapchat':
        return ApiConfig.apiFuctions;
      default:
        return null;
    }
  }

  /// Obtener el endpoint correcto según la red social
  String _getProfileEndpoint(String network) {
    switch (network.toLowerCase()) {
      case 'youtube':
        return '/youtube/profile';
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
        // Si agregas nuevas plataformas en el backend puedes manejar aquí.
        throw Exception('Red social no soportada: $network');
    }
  }

  // ==================== MÉTODOS ESPECÍFICOS ====================
  Future<Map<String, dynamic>> getYouTubeProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'youtube',
        usernameOrLink: usernameOrLink,
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

  Future<Map<String, dynamic>> getTrovoProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'trovo',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getSpotifyProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'spotify',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getRedditProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'reddit',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getThreadsProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'threads',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getPinterestProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'pinterest',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getSoundCloudProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'soundcloud',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getAppleMusicProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'applemusic',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getDeezerProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'deezer',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getDiscordProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'discord',
        usernameOrLink: usernameOrLink,
      );

  Future<Map<String, dynamic>> getSnapchatProfile(String usernameOrLink) =>
      getProfileByUsernameOrLink(
        network: 'snapchat',
        usernameOrLink: usernameOrLink,
      );
}
