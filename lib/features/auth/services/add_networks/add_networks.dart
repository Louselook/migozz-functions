import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';
// import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';
import 'package:url_launcher/url_launcher_string.dart'; // <--- necesario para launchUrlString

class AddNetworkService {
  /// Obtiene perfil de Instagram
  Future<Map<String, dynamic>> getInstagramProfile({
    required String usernameOrLink,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/networks/add-instagram',
    ).replace(queryParameters: {'username_or_link': usernameOrLink});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error obteniendo perfil de Instagram: ${response.body}');
    }
  }

  /// Obtiene perfil de YouTube
  Future<Map<String, dynamic>> getYouTubeProfile({
    required String handleOrUrl,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/youtube/channel',
    ).replace(queryParameters: {'query': handleOrUrl});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error obteniendo perfil de YouTube: ${response.body}');
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

  Future<void> startFacebookAuth(BuildContext context) async {
    final url = Uri.parse('${ApiConfig.apiBase}/facebook/auth');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        await launchUrlString(authUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Error al obtener URL de Facebook: ${response.body}');
      }
    } catch (e) {
      debugPrint('No se pudo abrir la URL de Facebook\nError: $e');
    }
  }
}
