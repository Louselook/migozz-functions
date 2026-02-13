import 'package:flutter/material.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserDTO user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 900;

    if (isWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BackgroundImage maneja el header visual (avatar, nombre, bio)
          BackgroundImage(
            avatarUrl: user.avatarUrl,
            voiceNoteUrl: user.voiceNoteUrl ?? '',
            name: user.displayName,
            displayName: '@${user.username}',
            comunityCount: _calculateTotalFollowers(user),
            nameComunity: 'Community',
            isOwnProfile: false,
            userId: user.email,
            child: _buildContent(context, isWeb: false),
          ),

          // Botón flotante "Descargar App"
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildDownloadAppButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 400, // Ancho tipo móvil
          height: 800,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackgroundImage(
                avatarUrl: user.avatarUrl,
                voiceNoteUrl: user.voiceNoteUrl ?? '',
                name: user.displayName,
                displayName: '@${user.username}',
                comunityCount: _calculateTotalFollowers(user),
                nameComunity: 'Community',
                isOwnProfile: false,
                userId: user.email,
                child: _buildContent(context, isWeb: true),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: _buildDownloadAppButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isWeb}) {
    // Contenido debajo del header
    final socialLinks = _parseSocialLinks(user);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      // Ajustamos el padding superior para que empiece debajo del header visual
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.45),
      child: Column(
        children: [
          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 20),
            // SocialRail maneja la lista de iconos sociales
            SocialRail(links: socialLinks),
          ],
          const SizedBox(height: 100), // Espacio para el botón flotante
        ],
      ),
    );
  }

  Widget _buildDownloadAppButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDownloadDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE91E63),
              Color(0xFFFF6F00),
            ], // Gradiente rosa/naranja
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Download Migozz App', // Debería estar localizado
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Get the Full Experience",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Download Migozz to connect, chat, and see full profiles.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StoreButton(
                  icon: Icons.apple,
                  label: "App Store",
                  onTap: () => _launchURL(
                    "https://apps.apple.com/us/app/migozz/id6502121020",
                  ), // Reemplazar con ID real
                ),
                _StoreButton(
                  icon: Icons.android,
                  label: "Google Play",
                  onTap: () => _launchURL(
                    "https://play.google.com/store/apps/details?id=com.migozz.app",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _calculateTotalFollowers(UserDTO user) {
    int total = 0;
    if (user.socialEcosystem != null) {
      for (final social in user.socialEcosystem!) {
        // Iteramos sobre las entradas del mapa (ej: {instagram: {...}})
        for (final entry in social.entries) {
          final data = entry.value;
          if (data is Map<String, dynamic>) {
            final followers = data['followers'];
            if (followers is int) {
              total += followers;
            } else if (followers is String) {
              total += int.tryParse(followers) ?? 0;
            }
          }
        }
      }
    }
    return _formatNumber(total);
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0'), '')}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0'), '')}K';
    }
    return n.toString();
  }

  List<SocialLink> _parseSocialLinks(UserDTO user) {
    final List<SocialLink> links = [];
    if (user.socialEcosystem != null) {
      for (final social in user.socialEcosystem!) {
        for (final entry in social.entries) {
          final platform = entry.key;
          final data = entry.value;

          if (data is Map<String, dynamic>) {
            final followers = int.tryParse(
              data['followers']?.toString() ?? '0',
            );
            final shares = int.tryParse(data['shares']?.toString() ?? '0');
            // La URL puede venir en 'url' o construirse
            String? urlString = data['url']?.toString();

            // Si no hay URL, intentamos construirla si tenemos username
            // Nota: Aquí data no parece tener 'username' de la red social,
            // así que asumimos que usa el username de Migozz si no hay URL específica
            // O bien la lógica de _buildSocialLinks en profile_page.dart usa user.username

            final socialInfo = _getSocialInfo(
              platform,
              user.username,
              urlString,
            );

            if (socialInfo != null) {
              links.add(
                SocialLink(
                  asset: socialInfo['asset']!,
                  url: Uri.parse(socialInfo['url']!),
                  followers: followers,
                  shares: shares,
                ),
              );
            }
          }
        }
      }
    }
    return links;
  }

  Map<String, String>? _getSocialInfo(
    String platform,
    String username,
    String? customUrl,
  ) {
    // Usamos el resolver centralizado
    final asset = SocialIconResolver.resolve(platform);
    if (asset == null) return null;

    String url;
    // Lógica simplificada de URL builder
    if (customUrl != null && customUrl.isNotEmpty) {
      url = customUrl;
    } else {
      // Fallback básico
      final cleanUsername = username.replaceFirst('@', '');
      switch (platform.toLowerCase()) {
        case 'tiktok':
          url = 'https://www.tiktok.com/@$cleanUsername';
          break;
        case 'instagram':
          url = 'https://www.instagram.com/$cleanUsername';
          break;
        case 'x':
        case 'twitter':
          url = 'https://x.com/$cleanUsername';
          break;
        case 'pinterest':
          url = 'https://www.pinterest.com/$cleanUsername';
          break;
        case 'youtube':
          url = 'https://www.youtube.com/@$cleanUsername';
          break;
        default:
          // Si no sabemos construirla y no viene customUrl, no podemos enlazar
          // Pero quizás queramos mostrar el icono igual.
          // Por ahora retornamos una búsqueda de google como fallback seguro
          url = 'https://www.google.com/search?q=$platform+$cleanUsername';
      }
    }

    // Asegurar esquema
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    return {'asset': asset, 'url': url};
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StoreButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
