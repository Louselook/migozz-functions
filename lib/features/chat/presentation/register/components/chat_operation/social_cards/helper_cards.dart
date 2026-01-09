import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';

class SocialCardsHelper {
  static List<Map<String, dynamic>> generateSocialCards({
    required List<Map<String, dynamic>> platforms,
    required bool isSpanish,
    required String Function() getTimeNow,
  }) {
    final List<Map<String, dynamic>> allPlatforms = [];

    for (var platform in platforms) {
      if (platform.isEmpty) continue;

      // Custom links (schema plano): no exponer URL; mostrar solo icono opcional, nombre de página y username
      final type = platform['type']?.toString().toLowerCase();
      if (type == 'custom') {
        final domain = _normalizeDomain(platform['domain']?.toString() ?? '');
        final pageLabel = domain.isEmpty ? 'Link' : domain;
        final username = _extractUsernameFromUrl(platform['url']?.toString() ?? '');
        final applyIcon = platform['applyIconFromLink'] == true;
        final storedIconUrl = platform['iconUrl']?.toString() ?? '';
        final iconUrl = applyIcon
            ? (storedIconUrl.isNotEmpty ? storedIconUrl : _faviconFromDomain(domain))
            : '';

        allPlatforms.add({
          "label": pageLabel,
          "iconPath": iconUrl,
          if (username.isNotEmpty) "username": '@$username',
        });
        continue;
      }

      final networkName = platform.keys.first; // youtube, instagram...
      final raw = platform[networkName];
      if (raw is! Map) continue;
      final networkData = Map<String, dynamic>.from(raw);

      final iconPath = iconByLabel[networkName.toLowerCase().capitalize()];

      // Extraer seguidores/suscriptores si existen
      final followers = _extractFollowers(
        networkName.toLowerCase(),
        networkData,
      );

      allPlatforms.add({
        ...networkData,
        "label": networkName.capitalize(),
        "iconPath": iconPath,
        if (followers != null) "followersFormatted": followers,
      });
    }

    return [
      {
        "other": true,
        "type": MessageType.socialCards,
        "platforms": allPlatforms,
        "time": getTimeNow(),
      },
    ];
  }

  static String? _extractFollowers(String network, Map<String, dynamic> data) {
    num? count;

    // Actualizado: Agregar más variantes para YouTube y otras redes
    final candidateKeys = [
      'followers',
      'followers_count',
      'follower_count',
      'edge_followed_by',
      'subscribers',
      'subscriberCount', // YouTube API
      'statistics.subscriberCount', // YouTube API anidado
    ];

    for (final key in candidateKeys) {
      if (key.contains('.')) {
        final parts = key.split('.');
        final root = data[parts[0]];
        if (root is Map && root[parts[1]] != null) {
          final v = root[parts[1]];
          count = _toNum(v);
        }
      } else if (data[key] != null) {
        count = _toNum(data[key]);
      }
      if (count != null) break;
    }

    if (count == null) return null;
    return _formatCompact(count);
  }

  static num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) {
      final sanitized = v.replaceAll(',', '').trim();
      return num.tryParse(sanitized);
    }
    return null;
  }

  static String _formatCompact(num n) {
    if (n >= 1000000000) {
      return '${(n / 1000000000).toStringAsFixed(n % 1000000000 == 0 ? 0 : 1)}B';
    }
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toString();
  }

  static String _normalizeDomain(String domain) {
    final d = domain.trim().toLowerCase();
    if (d.startsWith('www.')) return d.substring(4);
    return d;
  }

  static String _extractUsernameFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return '';
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    if (segments.isEmpty) return '';
    var candidate = segments.last.trim();
    if (candidate.startsWith('@')) candidate = candidate.substring(1);
    return candidate;
  }

  static String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
