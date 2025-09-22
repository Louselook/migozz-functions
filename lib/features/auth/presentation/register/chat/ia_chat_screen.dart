// lib/features/auth/presentation/register/chat/ia_chat_screen.dart (Refactorizado)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input_widget.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_message_builder.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_navigation_handler.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'components/suggestion_chips.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    _chatController.addListener(_onChatStateChanged);
    _chatController.initializeChat(
      onActionRequired: (botResponse) {
        ChatNavigationHandler.handleBotAction(
          context: context,
          botResponse: botResponse,
          chatController: _chatController,
        );
      },
    );
  }

  @override
  void dispose() {
    _chatController.removeListener(_onChatStateChanged);
    _chatController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChatStateChanged() {
    setState(() {});
  }

  void _doneChat(BuildContext context, RegisterCubit cubit) async {
    try {
      debugPrint(" Usuario final: ${cubit.state}");
      final testUser = cubit.state.buildUserDTO();

      final authService = AuthService();

      final userCredential = await authService.signUpRegister(
        email: cubit.state.email!,
        otp: "123456", // contraseña temporal o el OTP que uses
        userData: testUser,
      );

      debugPrint(" Usuario creado en Firebase: ${userCredential.user?.uid}");

      //  Mostrar snackbar de éxito
      CustomSnackbar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: "Registro completado con éxito ",
        type: SnackbarType.success,
      );
    } catch (e) {
      debugPrint(" Error al registrar: $e");

      //  Mostrar snackbar de error
      CustomSnackbar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: "Error al registrar: $e",
        type: SnackbarType.error,
      );
    }
  }

  void _handleSendMessage() {
    final text = _controller.text;
    _controller.clear();

    final cubit = context.read<RegisterCubit>();
    final step = cubit.state.currentStep;

    switch (step) {
      case RegisterStep.chatQuestions:
        if (cubit.state.language == null) {
          cubit.setLanguage(text);
        } else if (cubit.state.fullName == null) {
          cubit.setFullName(text);
        } else if (cubit.state.username == null) {
          cubit.setUsername(text);
        } else if (cubit.state.gender == null) {
          cubit.setGender(text);
        } else if (cubit.state.location == null) {
          cubit.setLocation(
            LocationDTO(
              country: "Colombia",
              state: "Antioquia",
              city: "Medellín",
              lat: 6.2442,
              lng: -75.5812,
            ),
          );
        }
        break;

      default:
        break;
    }

    _chatController.sendMessage(
      text,
      onActionRequired: (botResponse) {
        ChatNavigationHandler.handleBotAction(
          context: context,
          botResponse: botResponse,
          chatController: _chatController,
        );
      },
    );

    if (cubit.state.currentStep == RegisterStep.finalReview) {
      _doneChat(context, cubit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText("IA Chat"),
            const SizedBox(height: 20),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _chatController.scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messages[index];
                  return ChatMessageBuilder.buildMessage(message);
                },
              ),
            ),

            // Dynamic Suggestions
            if (_chatController.currentSuggestions.isNotEmpty)
              SuggestionChips(
                suggestions: _chatController.currentSuggestions,
                onSelected: (choice) {
                  _chatController.sendMessage(
                    choice,
                    onActionRequired: (botResponse) {
                      ChatNavigationHandler.handleBotAction(
                        context: context,
                        botResponse: botResponse,
                        chatController: _chatController,
                      );
                    },
                  );
                },
              ),

            // Input Bar
            ChatInputWidget(
              controller: _controller,
              onSend: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
