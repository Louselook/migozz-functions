import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/audio/audio_playback_widget.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_typing.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/social_cards/social_cards.dart';

class ChatMessageBuilder {
  static Widget buildMessage(
    Map<String, dynamic> message, {
    dynamic chatController,
    String? otherUserName, // 👈 NUEVO
    String? otherUserAvatar, // 👈 NUEVO
  }) {
    if (message["type"] == MessageType.typing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [OtherTyping(name: message["name"] ?? "IA")],
        ),
      );
    }

    if (message["type"] == MessageType.pictureCard) {
      final pics = List<Map<String, String>>.from(message["pictures"]);
      final isFromOther = message["other"] == true;

      // ✅ Determinar nombre y avatar del remitente
      String? senderName;
      String? senderAvatar;

      if (isFromOther) {
        // Es del otro usuario
        senderName = otherUserName ?? message["senderName"];
        senderAvatar = otherUserAvatar ?? message["senderAvatar"];
      } else {
        // Es del usuario actual
        senderName = message["senderName"] ?? "Tú";
        senderAvatar = message["senderAvatar"];
      }

      return PictureOptions(
        pictures: pics,
        time: message["time"],
        sender: isFromOther,
        senderName: senderName, // 👈 NUEVO
        senderAvatar: senderAvatar, // 👈 NUEVO
      );
    }

    if (message["type"] == MessageType.socialCards) {
      return OtherMessage(
        text: "Aquí está la información extraída de sus redes sociales.",
        time: message["time"] ?? "",
        platforms: List<Map<String, dynamic>>.from(message["platforms"]),
        chatController: chatController,
      );
    }

    if (message["type"] == MessageType.audio) {
      final audioPath = message["audio"] as String;
      final other = message["other"] == true;
      final controller = message["chatController"];

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
              chatController: controller,
              // ✅ NUEVO: Pasar info del otro usuario para audio
              otherUserName: other ? otherUserName : null,
              otherUserAvatar: other ? otherUserAvatar : null,
            ),
          ],
        ),
      );
    }

    if (message["other"] == true) {
      if (message["social"] == true) {
        final platformData = message["platform"] as Map<String, dynamic>;
        return SocialCardMini(platformData: platformData);
      }

      return OtherMessage(
        text: message["text"] ?? "",
        time: message["time"] ?? "",
        platforms: message["platforms"] != null
            ? List<Map<String, dynamic>>.from(message["platforms"])
            : null,
        profilePictures: message["profilePictures"] != null
            ? List<Map<String, String>>.from(message["profilePictures"])
            : null,
        chatController: chatController,
        // ✅ NUEVO: Pasar nombre y avatar del otro usuario
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
      );
    } else {
      return UserMessage(text: message["text"] ?? "");
    }
  }
}
