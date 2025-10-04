import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';

class ChatNavigationHandler {
  static void handleBotAction({
    required BuildContext context,
    required Map<String, dynamic> botResponse,
    required ChatController chatController,
  }) {
    if (botResponse["dinamicResponse"] == "FollowedMessages") {
      _handlePostNavigationFlowPicture(chatController);
    }

    if (botResponse["action"] != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        // Obtener el cubit actual antes de navegar
        // ignore: use_build_context_synchronously
        final cubit = context.read<RegisterCubit>();
        final int action = (botResponse["action"] as int?) ?? 0;

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit, // Pasar la instancia existente del cubit
              child: MoreUserDetails(pageIndicator: botResponse["action"]),
            ),
          ),
        ).then((result) {
          if (result == "done") {
            switch (action) {
              case 0:
                _handlePostNavigationFlowSocial(chatController);
                break;
              case 1:
                _handlePostNavigationFlowCategory(chatController);
                break;
              case 2:
                // ignore: use_build_context_synchronously
                _handlePostNavigationFlowInterests(context, chatController);
                break;
              default:
                chatController.showNextBotMessage();
                break;
            }
          }
        });
      });
    }
  }

  static void _handlePostNavigationFlowSocial(
    ChatController chatController,
  ) async {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      chatController.showNextBotMessage(); // uno por defecto
      await chatController.addSocialCards();
      // Mostrar confirmación de avatar si aplica
      await _maybeAskUseInstagramAvatar(chatController);
      await chatController.showMultipleBotMessages(1); // n mensajes
    });
  }

  // pictures
  static void _handlePostNavigationFlowPicture(ChatController chatController) {
    // Mostrar 3 mensajes consecutivos después del "Congratulations!" inicial
    Future.delayed(const Duration(milliseconds: 1200), () async {
      await chatController.showMultipleBotMessages(1);
      await chatController.addPictureCards();
      chatController.showNextBotMessage();
    });
  }

  static void _handlePostNavigationFlowCategory(
    ChatController chatController,
  ) async {
    Future.delayed(const Duration(milliseconds: 800), () async {
      // Mostrar el siguiente mensaje (abrirá intereses por acción:2)
      await chatController.showMultipleBotMessages(1);
    });
  }

  static void _handlePostNavigationFlowInterests(
    BuildContext context,
    ChatController chatController,
  ) async {
    Future.delayed(const Duration(milliseconds: 800), () async {
      // Mensajes de cierre: "Gracias..." y "Registro completo..."
      await chatController.showMultipleBotMessages(2);
      // Redirigir al perfil tras pequeño delay
      await Future.delayed(const Duration(milliseconds: 600));
      if (context.mounted) context.go('/profile');
    });
  }

  static Future<void> _maybeAskUseInstagramAvatar(
    ChatController chatController,
  ) async {
    final cubit = chatController.registerCubit;
    final socials = cubit.state.socialEcosystem ?? [];
    final hasInstagram = socials.any((e) => e.keys.first == 'instagram');
    final avatar = cubit.state.avatarUrl;
    if (!hasInstagram || avatar == null || avatar.isEmpty) return;

    // Pregunta al usuario si quiere usar su foto de Instagram
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');
    final question = isSpanish
        ? '¿Quieres usar tu foto de Instagram como avatar?'
        : 'Do you want to use your Instagram photo as your avatar?';

    // Activar modo de confirmación en el controlador
    chatController.expectInstagramAvatarConfirmation();

    // Inyectar mensaje del bot con opciones Sí/No
    // Usamos la API pública del controlador para añadir un mensaje bot
    // (no avanzamos el índice del guion, solo mostramos la pregunta)
    chatController.sendChat(
      other: true,
      text: question,
      options: isSpanish ? ['Sí', 'No'] : ['Yes', 'No'],
    );
  }
}
