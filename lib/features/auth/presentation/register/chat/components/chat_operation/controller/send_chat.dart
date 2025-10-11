import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';

Future<void> sendChat({
  required bool other,
  required ChatControllerTest controller,
  required BuildContext context,
  MessageType type = MessageType.text,
  String? text,
  String? audio,
  List<Map<String, String>>? pictures,
  List<String>? options,
}) async {
  // 🎵 Manejar audio del usuario con el AudioHandler
  if (!other && type == MessageType.audio && audio != null) {
    await controller.sendUserAudio(audio);
    return;
  }

  if (other) {
    // Mensaje del bot → agregar directamente
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
    // ⚠️ MENSAJE DEL USUARIO → NO agregar aquí, delegar al controller
    // El controller.sendUserMessage() ya se encarga de agregarlo

    if (type == MessageType.text && (text?.trim().isNotEmpty ?? false)) {
      await controller.sendUserMessage(
        text!,
      ); // Ya agrega el mensaje internamente
    } else if (type == MessageType.pictureCard && pictures != null) {
      // Para imágenes, agregar directamente (no pasa por IA)
      controller.addMessage({
        "other": false,
        "type": type,
        "pictures": pictures,
        "time": getTimeNow(),
      });
    }
  }
}
