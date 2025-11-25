import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AddNetworkServiceClick {
  /// Método genérico para iniciar autenticación OAuth
  Future<void> startOAuthAuth({
    required BuildContext context,
    required String network,
  }) async {
    final endpoint = _getOAuthEndpoint(network);
    final url = Uri.parse('${ApiConfig.apiBase}$endpoint');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        await launchUrlString(authUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [$network] OAuth iniciado correctamente');
      } else {
        debugPrint('❌ [$network] Error al obtener URL: ${response.body}');
        // ignore: use_build_context_synchronously
        _showErrorSnackbar(context, network);
      }
    } catch (e) {
      debugPrint('❌ [$network] No se pudo abrir la URL\nError: $e');
      // ignore: use_build_context_synchronously
      _showErrorSnackbar(context, network);
    }
  }

  /// Obtener el endpoint correcto según la red social
  String _getOAuthEndpoint(String network) {
    switch (network.toLowerCase()) {
      case 'instagram':
        return '/instagram/auth';
      case 'twitter':
        return '/twitter/auth';
      case 'spotify':
        return '/spotify/auth';
      case 'tiktok':
        return '/tiktok/auth';
      case 'facebook':
        return '/facebook/auth';
      case 'youtube':
        return '/youtube/auth'; // Endpoint futuro para YouTube OAuth
      case 'linkedin':
        return '/linkedin/auth'; // Endpoint futuro
      case 'twitch':
        return '/twitch/auth'; // Endpoint futuro
      default:
        throw Exception('Red social no soportada: $network');
    }
  }

  /// Mostrar error al usuario
  void _showErrorSnackbar(BuildContext context, String network) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error connecting to $network. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Métodos específicos por red (opcionales, para compatibilidad)
  Future<void> startInstagramAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'instagram');

  Future<void> startTwitterAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'twitter');

  Future<void> startSpotifyAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'spotify');

  Future<void> startTikTokAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'tiktok');

  Future<void> startFacebookAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'facebook');

  Future<void> startYouTubeAuth(BuildContext context) =>
      startOAuthAuth(context: context, network: 'youtube');
}
