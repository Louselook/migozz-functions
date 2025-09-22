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
            _handlePostNavigationFlow(chatController);
          }
        });
      });
    }
  }

  static void _handlePostNavigationFlow(ChatController chatController) {
    chatController.handlePostActionResponse(
      onSocialEcosystem: () {
        // 👉 Después de mostrar mensaje introductorio, agregamos cards
        chatController.addSocialCards().then((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            // Continuamos con el siguiente mensaje del flujo
            chatController.showNextBotMessage();
          });
        });
      },
      onNormalFlow: () {
        Future.delayed(const Duration(milliseconds: 600), () {
          chatController.showNextBotMessage();
        });
      },
    );
  }
}
