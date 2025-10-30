import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/chat_input_widget.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/send_chat.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/suggestion_chips.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/chat_navigation_handler.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/deeplink_functions/handle_facebook.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/deeplink_functions/handle_spotify.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/deeplink_functions/handle_tiktok.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/deeplink_functions/handle_twitter.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  static const _socialChannel = MethodChannel('socialAuth');
  final TextEditingController _controller = TextEditingController();
  late final ChatController _chatController;

  final GlobalKey<ChatInputWidgetState> _chatInputKey = GlobalKey();
  // Callback para eliminacion de audio al enviar

  @override
  void initState() {
    super.initState();

    _chatController = ChatController(
      registerCubit: context.read<RegisterCubit>(),
    );

    _chatController.onResetAudioUI = () {
      _chatInputKey.currentState?.resetAudioManager();
    };

    if (_chatController.messages.isEmpty) {
      _chatController.initializeChat(onActionRequired: _handleNavigation);
    }

    _socialChannel.setMethodCallHandler((call) async {
      if (call.method == 'spotifySuccess') {
        handleSpotify(call.arguments as String, context);
      } else if (call.method == 'twitterSuccess') {
        handleTwitter(call.arguments as String, context);
      } else if (call.method == 'facebookSuccess') {
        handleFacebook(call.arguments as String, context);
      } else if (call.method == 'tiktokSuccess') {
        handleTikTok(call.arguments as String, context);
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleNavigation(Map<String, dynamic> botResponse) {
    ChatNavigationHandler.handleBotAction(
      context: context,
      botResponse: botResponse,
      chatController: _chatController,
    );
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

            // Messages list
            Expanded(
              child: ListenableBuilder(
                listenable: _chatController,
                builder: (context, child) {
                  return ListView.builder(
                    controller: _chatController.scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _chatController.messages.length,
                    itemBuilder: (context, index) {
                      final message = _chatController.messages[index];
                      final isLastBotMsgWithOptions =
                          message["other"] == true &&
                          (message["options"] != null &&
                              (message["options"] as List).isNotEmpty) &&
                          !_chatController.messages
                              .sublist(index + 1)
                              .any(
                                (m) =>
                                    m["other"] == true &&
                                    (m["options"] != null &&
                                        (m["options"] as List).isNotEmpty),
                              );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChatMessageBuilder.buildMessage(
                            message,
                            chatController: _chatController,
                          ),
                          if (isLastBotMsgWithOptions)
                            SuggestionChips(
                              suggestions: List<String>.from(message["options"]),
                              onSelected: (suggestion) {
                                _chatController.onSuggestionSelected(suggestion);
                              },
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            ListenableBuilder(
              listenable: _chatController,
              builder: (context, child) {
                return ChatInputWidget(
                  key: _chatInputKey,
                  controller: _controller,
                  showPhoneInput: _chatController.showPhoneInput,
                  onSend: () {
                    sendChat(
                      other: false,
                      type: MessageType.text,
                      text: _controller.text,
                      controller: _chatController,
                      context: context,
                    );
                    _controller.clear();
                  },

                  // Safety: if web -> send fallback text; else send audio as before
                  onSendAudio: (path) {
                    if (kIsWeb) {
                      sendChat(
                        other: false,
                        type: MessageType.text,
                        text: "If you'd like to add images or audio, please use the app!",
                        controller: _chatController,
                        context: context,
                      );
                    } else {
                      sendChat(
                        other: false,
                        type: MessageType.audio,
                        audio: path,
                        controller: _chatController,
                        context: context,
                      );
                    }
                  },

                  // Safety: if web -> fallback text; else send image as before
                  onSendImage: (path) {
                    if (kIsWeb) {
                      sendChat(
                        other: false,
                        type: MessageType.text,
                        text: "If you'd like to add images or audio, please use the app!",
                        controller: _chatController,
                        context: context,
                      );
                    } else {
                      sendChat(
                        other: false,
                        type: MessageType.pictureCard,
                        pictures: [
                          {"imageUrl": path, "label": "Mi Imagen"},
                        ],
                        controller: _chatController,
                        context: context,
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
