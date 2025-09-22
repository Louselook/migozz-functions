// lib/features/auth/presentation/register/chat/builders/chat_message_builder.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import '../social_card.dart';

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
      return OtherMessage(text: message["text"], time: message["time"] ?? "");
    } else {
      return UserMessage(text: message["text"]);
    }
  }
}
