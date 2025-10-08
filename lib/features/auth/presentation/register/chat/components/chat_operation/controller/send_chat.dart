// send_chat.dart (usa esta versión)
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';

void sendChat({
  required bool other,
  required ChatControllerTest controller,
  required BuildContext context,
  MessageType type = MessageType.text,
  String? text,
  String? audio,
  List<Map<String, String>>? pictures,
  List<String>? options,
}) {
  if (other) {
    // Mensaje del bot u otro
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
    // Mensaje del usuario → el controlador se encarga del flujo IA
    // NOTA: ya no se pasa callback onActionRequired aquí; la UI debe haber registrado onBotAction al inicializar
    controller.sendUserMessage(text ?? '');
  }
}
