import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/social_ecosystem_handler.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';

/// Maneja las acciones que el bot indica en su respuesta
class ChatNavigationHandler {
  static void handleBotAction({
    required BuildContext context,
    required Map<String, dynamic> botResponse,
    required ChatController chatController,
  }) async {
    final action = botResponse["action"];
    if (action == null) return;

    final cubit = context.read<RegisterCubit>();

    switch (action) {
      case 0:
        // 🔹 Navegar a SocialEcosystemStep y esperar resultado
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: MoreUserDetails(pageIndicator: action),
            ),
          ),
        );

        // 🔹 Manejar retorno de redes sociales (delegado a handler específico)
        if (result == 'done' && context.mounted) {
          SocialEcosystemHandler.handleReturn(
            context: context,
            cubit: cubit,
            chatController: chatController,
          );
        }
        break;

      case 1:
        // 🔹 Otro paso (CategoryStep)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: MoreUserDetails(pageIndicator: action),
            ),
          ),
        );
        break;

      case 2:
        // 🔹 Último paso (InterestsStep)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: MoreUserDetails(pageIndicator: action),
            ),
          ),
        );
        break;

      default:
        debugPrint("⚠️ Acción desconocida: $action");
    }
  }
}
