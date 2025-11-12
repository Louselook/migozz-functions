import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';

/// Función auxiliar para enviar mensajes en el chat de registro
/// Maneja diferentes tipos de mensajes: texto, audio, imágenes
Future<void> sendChat({
  required bool other,
  required RegisterChatController controller,
  required BuildContext context,
  MessageType type = MessageType.text,
  String? text,
  String? audio,
  List<Map<String, String>>? pictures,
  List<String>? options,
}) async {
  // 🎵 Manejar audio del usuario
  if (!other && type == MessageType.audio && audio != null) {
    await controller.sendUserAudio(audio);
    return;
  }

  // 📸 Manejar foto de avatar
  if (!other &&
      type == MessageType.pictureCard &&
      pictures != null &&
      pictures.isNotEmpty) {
    final photoPath = pictures.first["imageUrl"];
    if (photoPath != null) {
      await controller.sendAvatarPhoto(photoPath);
      return;
    }
  }

  if (other) {
    // ✅ Mensaje del bot → agregar directamente
    // (Esto normalmente se hace desde showNextBotMessage)
    controller.addMessage({
      "other": true,
      "type": type,
      "text": text,
      "audio": audio,
      "pictures": pictures,
      "options": options ?? [],
      "time": getTimeNow(),
    });
  } else {
    // ✅ Mensaje del usuario → delegar al controller
    // El controller maneja toda la lógica de validación y respuesta de IA
    if (type == MessageType.text && (text?.trim().isNotEmpty ?? false)) {
      await controller.sendTextMessage(text!);
    }
  }
}
