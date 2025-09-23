import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import '../../../../features/auth/presentation/register/chat/components/social_card.dart';

class ChatMessageBuilder {
  static Widget buildMessage(Map<String, dynamic> message) {
    if (message["isBot"]) {
      if (message["social"] == true) {
        return buildSocialCard(
          message["platform"],
          message["stats"],
          message["emoji"],
          message["time"],
        );
      }

      if (message["picture"] == true) {
        return PictureOptions(
          pictures: message["pictures"] ?? [],
          time: message["time"] ?? "",
        );
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
