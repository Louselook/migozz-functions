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

      messages.add({
        "other": true,
        "type": MessageType.socialCard,
        "social": true,
        "platform": {
          ...networkData,
          "label": networkName.capitalize(),
          "iconPath": iconPath,
        },
        "time": getTimeNow(),
      });
    }

    return messages;
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
