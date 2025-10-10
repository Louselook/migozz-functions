import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/audio/audio_playback_widget.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_typing.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/social_cards/social_cards.dart';

class ChatMessageBuilder {
  static Widget buildMessage(Map<String, dynamic> message) {
    // Mensaje de typing (IA escribiendo)
    if (message["type"] == MessageType.typing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [OtherTyping(name: message["name"] ?? "IA")],
        ),
      );
    }

    // Mensajes de imagen (URL o local)
    if (message["type"] == MessageType.pictureCard) {
      final pics = List<Map<String, String>>.from(message["pictures"]);
      return PictureOptions(
        pictures: pics,
        time: message["time"],
        sender: message["other"],
      );
    }

    // Social cards
    if (message["type"] == MessageType.socialCards) {
      return OtherMessage(
        text: "Aquí está la información extraída de sus redes sociales.",
        time: message["time"] ?? "",
        platforms: List<Map<String, dynamic>>.from(message["platforms"]),
      );
    }

    // 🎵 Mensajes de audio - Diseño horizontal con waveform
    if (message["type"] == MessageType.audioPlayback) {
      final audioPath = message["audio"] as String;
      final other = message["other"] == true;
      final chatController = message["chatController"];

      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: other
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            AudioPlaybackWidget(
              audioPath: audioPath,
              other: other,
              chatController: chatController,
            ),
          ],
        ),
      );
    }

    // Mensajes de texto y social card individual
    if (message["other"] == true) {
      if (message["social"] == true) {
        final platformData = message["platform"] as Map<String, dynamic>;
        return SocialCardMini(platformData: platformData);
      }

      return OtherMessage(
        text: message["text"] ?? "",
        time: message["time"] ?? "",
      );
    } else {
      return UserMessage(text: message["text"] ?? "");
    }
  }
}
