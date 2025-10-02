import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';
import 'package:url_launcher/url_launcher_string.dart'; // <--- necesario para launchUrlString

class AddNetworkService {
  /// Obtiene perfil de Instagram
  Future<ProfileData> getInstagramProfile({
    required String usernameOrLink,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/networks/add-instagram',
    ).replace(queryParameters: {'username_or_link': usernameOrLink});

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileData.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Perfil no encontrado: $usernameOrLink');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error obteniendo perfil de Instagram: $e');
    }
  }

  /// Obtiene perfil de YouTube
  Future<ProfileData> getYouTubeProfile({required String handleOrUrl}) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/youtube/channel',
    ).replace(queryParameters: {'query': handleOrUrl});

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Convertimos la respuesta a ProfileData
        return ProfileData(
          url: data['customUrl'] ?? '',
          username: data['title'] ?? handleOrUrl,
          fullName: data['title'] ?? handleOrUrl,
          profilePicUrl: data['thumbnail'] ?? '',
          followers: int.tryParse(data['subscriberCount'] ?? '0') ?? 0,
          followees: 0,
          totalPosts: int.tryParse(data['videoCount'] ?? '0') ?? 0,
        );
      } else if (response.statusCode == 404) {
        throw Exception('Canal no encontrado: $handleOrUrl');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error obteniendo perfil de YouTube: $e');
    }
  }

  /// Inicia autenticación de Twitter mediante deep link
  Future<void> startTwitterAuth(BuildContext context) async {
    final url = Uri.parse('${ApiConfig.apiBase}/twitter/auth');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        await launchUrlString(authUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Error al obtener URL de Twitter: ${response.body}');
      }
    } catch (e) {
      debugPrint('No se pudo abrir la URL de Twitter\nError: $e');
    }
  }

  /// Inicia autenticación de Spotify mediante deep link
  Future<void> startSpotifyAuth(BuildContext context) async {
    final url = Uri.parse('${ApiConfig.apiBase}/spotify/auth');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        await launchUrlString(authUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Error al obtener URL de Spotify: ${response.body}');
      }
    } catch (e) {
      debugPrint('No se pudo abrir la URL de Spotify\nError: $e');
    }
  }

  /// Inicia autenticación de TikTok mediante deep link
  Future<void> startTikTokAuth(BuildContext context) async {
    final url = Uri.parse('${ApiConfig.apiBase}/tiktok/auth');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        await launchUrlString(authUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Error al obtener URL de TikTok: ${response.body}');
      }
    } catch (e) {
      debugPrint('No se pudo abrir la URL de TikTok\nError: $e');
    }
  }
}
