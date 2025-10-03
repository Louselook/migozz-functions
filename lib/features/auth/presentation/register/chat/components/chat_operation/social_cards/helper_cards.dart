import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';

class SocialCardsHelper {
  static List<Map<String, dynamic>> generateSocialCards({
    required List<Map<String, Map<String, dynamic>>> platforms,
    required bool isSpanish,
    required String Function() getTimeNow,
  }) {
    final List<Map<String, dynamic>> messages = [];

    for (var platform in platforms) {
      final networkName = platform.keys.first; // youtube, instagram...
      final networkData = platform[networkName]!;

      final iconPath = iconByLabel[networkName.toLowerCase().capitalize()];

      // Extraer seguidores/suscriptores si existen
      final followers = _extractFollowers(
        networkName.toLowerCase(),
        networkData,
      );

      messages.add({
        "other": true,
        "type": MessageType.socialCard,
        "social": true,
        "platform": {
          ...networkData,
          "label": networkName.capitalize(),
          "iconPath": iconPath,
          if (followers != null) "followersFormatted": followers,
        },
        "time": getTimeNow(),
      });
    }

    return messages;
  }

  static String? _extractFollowers(String network, Map<String, dynamic> data) {
    num? count;
    // Campos comunes devueltos por nuestros endpoints
    final candidateKeys = [
      'followers',
      'followers_count',
      'follower_count',
      'edge_followed_by', // IG Graph name sometimes nested
      'subscribers',
      'subscriberCount',
      'statistics.subscriberCount', // YouTube API style (string)
    ];

    for (final key in candidateKeys) {
      if (key.contains('.')) {
        // Soporta un nivel de anidación simple
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
    if (v is num) return v;
    if (v is String) {
      final sanitized = v.replaceAll(',', '');
      return num.tryParse(sanitized);
    }
    return null;
  }

  static String _formatCompact(num n) {
    if (n >= 1000000000)
      return (n / 1000000000).toStringAsFixed(n % 1000000000 == 0 ? 0 : 1) +
          'B';
    if (n >= 1000000)
      return (n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1) + 'M';
    if (n >= 1000)
      return (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1) + 'K';
    return n.toString();
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
