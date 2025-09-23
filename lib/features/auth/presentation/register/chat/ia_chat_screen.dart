// lib/features/auth/presentation/register/chat/ia_chat_screen.dart (Refactorizado)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input_widget.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
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
      // datos para pruebas
      final filledState = cubit.state.copyWith(
        avatarUrl: "https://picsum.photos/200",
        phone: "+57 3001234567",
        voiceNoteUrl: "https://storage.fake/voice123.mp3",
        category: "technology",
        interests: {
          "music": ["rock", "pop"],
          "sports": ["fútbol", "ciclismo"],
        },
      );
      debugPrint(" Usuario final (mockeado): $filledState");
      final testUser = filledState.buildUserDTO();

      /// Toda eesta logica pasarla al cubit
      // datos reales
      // final testUser = cubit.state.buildUserDTO();

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

    if (cubit.state.language == null) {
      cubit.setLanguage(text.isNotEmpty ? text : "es-CO");
    } else if (cubit.state.fullName == null) {
      cubit.setFullName(text.isNotEmpty ? text : "Juan Pérez");
    } else if (cubit.state.username == null) {
      cubit.setUsername(text.isNotEmpty ? text : "juanito123");
    } else if (cubit.state.gender == null) {
      cubit.setGender(text.isNotEmpty ? text : "male");
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
      // } else if (cubit.state.avatarUrl == null) {
      //   cubit.setAvatarUrl("https://picsum.photos/200"); // mock avatar
      // } else if (cubit.state.phone == null) {
      //   cubit.setPhone("+57 3001234567");
      // } else if (cubit.state.voiceNoteUrl == null) {
      //   cubit.setVoiceNoteUrl("https://storage.fake/voice123.mp3");
      // } else if (cubit.state.category == null) {
      //   cubit.setCategory("technology");
      // } else if (cubit.state.interests == null) {
      //   cubit.setInterests({
      //     "music": ["rock", "pop"],
      //     "sports": ["fútbol", "ciclismo"],
      //   });
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

    if (cubit.state.location != null) {
      // _doneChat(context, cubit);
      debugPrint('envio');
    }
    // if (cubit.state.isComplete) {
    //   _doneChat(context, cubit);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText("AI ASSISTANT"),
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
