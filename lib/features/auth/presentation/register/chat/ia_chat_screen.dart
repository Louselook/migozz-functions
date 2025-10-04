import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/chat_input_widget.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_navigation_handler.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/suggestion_chips.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  static const _spotifyChannel = MethodChannel('socialAuth');
  final TextEditingController _controller = TextEditingController();
  late final ChatController _chatController;
  String? myOTP;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      registerCubit: context.read<RegisterCubit>(),
    );

    // Solo inicializa si no hay mensajes previos
    if (_chatController.messages.isEmpty) {
      _chatController.initializeChat();
    }

    _chatController.addListener(_onChatStateChanged);

    // Deeplink Spotify
    _spotifyChannel.setMethodCallHandler((call) async {
      if (call.method == 'spotifySuccess') {
        final queryString = call.arguments as String;
        final params = Uri.splitQueryString(queryString);

        final registerCubit = context.read<RegisterCubit>();
        final current = List<Map<String, Map<String, dynamic>>>.from(
          registerCubit.state.socialEcosystem ?? [],
        );

        current.add({
          'spotify': {
            'access_token': params['access_token'],
            'refresh_token': params['refresh_token'],
            'display_name': params['display_name'],
            'email': params['email'],
            'followers': int.tryParse(params['followers'] ?? '0') ?? 0,
            'pais': params['pais'],
            'plan': params['plan'],
          },
        });

        registerCubit.setSocialEcosystem(current);
      }
    });
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
                padding: const EdgeInsets.all(10),
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messages[index];
                  final isLastBotMsgWithOptions =
                      message["other"] == true &&
                      (message["options"] != null &&
                          (message["options"] as List).isNotEmpty) &&
                      // Solo mostrar para el último mensaje del bot con opciones
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
                      ChatMessageBuilder.buildMessage(message),
                      if (isLastBotMsgWithOptions)
                        SuggestionChips(
                          suggestions: List<String>.from(message["options"]),
                          onSelected: (choice) {
                            _chatController.sendChat(
                              other: false,
                              text: choice,
                              onActionRequired: (botResponse) {
                                ChatNavigationHandler.handleBotAction(
                                  context: context,
                                  botResponse: botResponse,
                                  chatController: _chatController,
                                );
                              },
                            );
                            _controller.clear();
                          },
                        ),
                    ],
                  );
                },
              ),
            ),

            // Input Bar
            ChatInputWidget(
              key: ValueKey(
                _chatController.keyboardType,
              ), // fuerza rebuild al cambiar keyboardType
              controller: _controller,
              keyboardType: _chatController.keyboardType,
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