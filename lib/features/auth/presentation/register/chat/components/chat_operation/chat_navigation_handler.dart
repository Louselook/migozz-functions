import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            _handlePostNavigationFlowSocial(chatController);
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
      await chatController.showMultipleBotMessages(1); // n mensajes
      await chatController.addSocialCards();
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
}
