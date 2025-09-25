import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input_widget.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_navigation_handler.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final ChatController _chatController;
  String? myOTP;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      registerCubit: context.read<RegisterCubit>(),
    );
    // los meensajees que eenvio
    _chatController.addListener(_onChatStateChanged);
    // Inicia con mnsaje del chat
    _chatController.initializeChat();
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

            // Input Bar
            ChatInputWidget(
              controller: _controller,

              /// Enviar texto
              onSend: () {
                _chatController.sendChat(
                  other: false,
                  type: MessageType.text,
                  text: _controller.text,
                  onActionRequired: (botResponse) {
                    ChatNavigationHandler.handleBotAction(
                      context: context,
                      botResponse: botResponse,
                      chatController: _chatController,
                    );
                  },
                );

                // Limpiar el input después de enviar
                _controller.clear();
              },

              /// Enviar audio
              onSendAudio: (path) {
                _chatController.sendChat(
                  other: false,
                  type: MessageType.audio,
                  audio: path,
                  onActionRequired: (botResponse) {
                    ChatNavigationHandler.handleBotAction(
                      context: context,
                      botResponse: botResponse,
                      chatController: _chatController,
                    );
                  },
                );
              },

              /// Enviar imagen
              onSendImage: (path) {
                debugPrint(path);
                _chatController.sendChat(
                  other: false,
                  type: MessageType.pictureCard,
                  pictures: [
                    {"imageUrl": path, "label": "Mi Imagen"},
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// sugerncias

            // Dynamic Suggestions
            // if (_chatController.currentSuggestions.isNotEmpty)
            //   SuggestionChips(
            //     suggestions: _chatController.currentSuggestions,
            //     onSelected: (choice) {
            //       _chatController.sendChat(other: false);
            //       //   choice,
            //       //   onActionRequired: (botResponse) {
            //       //     ChatNavigationHandler.handleBotAction(
            //       //       context: context,
            //       //       botResponse: botResponse,
            //       //       chatController: _chatController,
            //       //     );
            //       //   },
            //       // );
            //     },
            //   ),