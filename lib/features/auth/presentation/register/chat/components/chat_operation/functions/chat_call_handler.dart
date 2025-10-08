import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

class ChatCallHandler {
  final RegisterCubit cubit;
  final ChatControllerTest controller;

  ChatCallHandler({required this.cubit, required this.controller});

  Future<void> handle(String callName, Map<String, dynamic> message) async {
    switch (callName) {
      case "sendEmailOtp":
        await _handleSendEmailOtp();
        break;

      case "verifyEmailOtp":
        await _handleVerifyEmailOtp();
        break;

      default:
        debugPrint('⚠️ [ChatCallHandler] No existe handler para "$callName"');
    }
  }

  /// 📨 Envía OTP al correo actual del cubit
  Future<void> _handleSendEmailOtp() async {
    debugPrint('📨 [sendEmailOtp] Iniciando envío de OTP');

    final email = cubit.state.email;
    if (email == null || email.trim().isEmpty) {
      controller.addMessage({
        "other": true,
        "text": "Parece que aún no has ingresado tu correo electrónico.",
        "type": MessageType.text,
        "time": getTimeNow(),
      });
      return;
    }

    // Mostrar mensaje de carga
    controller.addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": "Migozz",
      "time": getTimeNow(),
    });

    try {
      debugPrint('📧 Enviando OTP a: $email');
      final result = await sendOTP(email: email);

      // Remover typing
      controller.messages.removeWhere(
        (msg) => msg["type"] == MessageType.typing,
      );

      if (result['sent'] == true) {
        final generatedOtp = result['myOTP']?.toString() ?? '';
        cubit.setCurrentOTP(generatedOtp);

        debugPrint(
          '✅ OTP enviado exitosamente. Código guardado: $generatedOtp',
        );

        controller.addMessage({
          "other": true,
          "text":
              "📬 Te envié un código de verificación a $email. Por favor, escríbelo aquí para continuar 🔒",
          "type": MessageType.text,
          "time": getTimeNow(),
          "__waitingForOtp": true, // 🔹 Marcador especial
        });
      } else {
        debugPrint('❌ Error al enviar OTP: ${result['error']}');
        controller.addMessage({
          "other": true,
          "text": "❌ No se pudo enviar el código. ¿Podrías intentar de nuevo?",
          "type": MessageType.text,
          "time": getTimeNow(),
        });
      }
    } catch (e) {
      debugPrint('💥 Excepción al enviar OTP: $e');
      controller.messages.removeWhere(
        (msg) => msg["type"] == MessageType.typing,
      );

      controller.addMessage({
        "other": true,
        "text": "💥 Hubo un error al enviar el código: ${e.toString()}",
        "type": MessageType.text,
        "time": getTimeNow(),
      });
    }
  }

  /// ✅ Valida el OTP ingresado por el usuario
  Future<void> _handleVerifyEmailOtp() async {
    debugPrint('🔐 [verifyEmailOtp] Iniciando validación de OTP');

    final lastUserMsg = controller.lastUserMessage;
    final expectedOtp = cubit.state.currentOTP;

    debugPrint('👤 Mensaje del usuario: "$lastUserMsg"');
    debugPrint('🔑 OTP esperado: "$expectedOtp"');

    if (lastUserMsg == null || lastUserMsg.trim().isEmpty) {
      controller.addMessage({
        "other": true,
        "text": "Por favor, ingresa el código que te envié al correo 📩",
        "type": MessageType.text,
        "time": getTimeNow(),
        "__waitingForOtp": true,
      });
      return;
    }

    if (expectedOtp == null || expectedOtp.trim().isEmpty) {
      controller.addMessage({
        "other": true,
        "text":
            "❌ No hay un código de verificación activo. ¿Deseas que te envíe uno nuevo?",
        "options": ["Sí, enviar código", "No"],
        "type": MessageType.text,
        "time": getTimeNow(),
      });
      return;
    }

    final trimmed = lastUserMsg.trim();

    if (trimmed == expectedOtp) {
      debugPrint('✅ OTP válido. Actualizando estado...');
      cubit.updateEmailVerification(EmailVerification.success);

      controller.addMessage({
        "other": true,
        "text":
            "✅ ¡Código correcto! Tu correo ha sido verificado exitosamente.",
        "type": MessageType.text,
        "time": getTimeNow(),
      });

      // 🔹 Disparar siguiente pregunta del bot
      Future.delayed(const Duration(milliseconds: 1000), () {
        controller.showNextBotMessage();
      });
    } else {
      debugPrint(
        '❌ OTP incorrecto. Esperado: "$expectedOtp", Recibido: "$trimmed"',
      );

      controller.addMessage({
        "other": true,
        "text":
            "❌ El código no coincide. Por favor, verifica e intenta nuevamente.",
        "type": MessageType.text,
        "time": getTimeNow(),
        "__waitingForOtp": true, // Seguir esperando
      });
    }
  }
}
