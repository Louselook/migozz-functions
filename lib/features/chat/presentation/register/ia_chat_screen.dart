import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/registration_handler.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/send_chat.dart';
import 'package:migozz_app/features/chat/presentation/register/components/suggestion_chips.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/chat_navigation_handler.dart';
import 'package:migozz_app/features/tutorial/avatar_register_tutorial.dart';
import 'package:migozz_app/features/tutorial/voice_register_tutorial.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final RegisterChatController _chatController;
  bool _isCompletingRegistration = false;

  final GlobalKey<ChatInputWidgetState> _chatInputKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // final registerCubit = context.read<RegisterCubit>();
    // final authCubit = context.read<AuthCubit>();
    final authState = context.read<AuthCubit>().state;
    final firebaseUid = authState.firebaseUser?.uid;

    debugPrint('🔑 [IaChatScreen] Firebase UID: $firebaseUid');

    _chatController = RegisterChatController(
      registerCubit: context.read<RegisterCubit>(),
      firebaseUid: firebaseUid,
    );

    _chatController.onResetAudioUI = () {
      _chatInputKey.currentState?.resetAudioManager();
    };

    _chatController.onShowAvatarTutorial = () => _showAvatarTutorial();
    _chatController.onShowVoiceNoteTutorial = () => _showVoiceNoteTutorial();

    if (_chatController.messages.isEmpty) {
      _chatController.initializeChat(onActionRequired: _handleNavigation);
    }
    _chatController.onRegistrationComplete = () async {
      if (_isCompletingRegistration) return;
      _isCompletingRegistration = true;

      final registerCubit = context.read<RegisterCubit>();
      final authCubit = context.read<AuthCubit>();
      final isGoogleUser =
          authCubit.state.isAuthenticated &&
          authCubit.state.firebaseUser != null;

      try {
        await registerCubit.checkCompletion(
          forGoogle: isGoogleUser,
          uid: isGoogleUser ? authCubit.state.firebaseUser!.uid : null,
        );

        if (!registerCubit.state.isComplete) {
          debugPrint(
            '⚠️ onRegistrationComplete: registerCubit not complete, aborting.',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faltan datos para completar el registro'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // ✅ NUEVA VALIDACIÓN: Solo validar email/OTP para usuarios NO autenticados
        if (!isGoogleUser) {
          final email = registerCubit.state.email;
          final otp = registerCubit.state.currentOTP;
          if (email == null ||
              email.trim().isEmpty ||
              otp == null ||
              otp.trim().isEmpty) {
            debugPrint(
              '⚠️ onRegistrationComplete: email/otp faltante: email=$email otp=$otp',
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Falta email o código OTP. Revisa el chat.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }

        if (!mounted) return;

        try {
          LoadingOverlay.show(context);
        } catch (_) {}

        await RegistrationHandler.completeRegistration(
          context: context,
          registerCubit: registerCubit,
          authCubit: authCubit,
        );

        if (!mounted) return;

        try {
          LoadingOverlay.hide(context);
        } catch (_) {}

        if (!mounted) return;
        context.go('/profile');
      } catch (e, st) {
        debugPrint('❌ Error en onRegistrationComplete wrapper: $e\n$st');
        try {
          LoadingOverlay.hide(context);
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finalizando registro: $e')),
        );
      } finally {
        _isCompletingRegistration = false;
      }
    };
  }

  bool _initializedLanguage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initializedLanguage) {
      final deviceLangCode = Localizations.localeOf(context).languageCode;
      final deviceLangLabel = deviceLangCode == 'es' ? 'Español' : 'English';

      context.read<RegisterCubit>().setLanguage(deviceLangLabel);
      GeminiService.instance.setLanguage(deviceLangLabel);

      _initializedLanguage = true;
    }
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

  // Método para mostrar el tutorial de avatar
  void _showAvatarTutorial() {
    final chatInputState = _chatInputKey.currentState;
    if (chatInputState == null) {
      debugPrint('⚠️ [IaChatScreen] ChatInputWidget state no disponible');
      return;
    }

    final attachButtonKey = chatInputState.attachButtonKey;
    final language = context.read<RegisterCubit>().state.language ?? 'English';

    debugPrint('📸 [IaChatScreen] Mostrando tutorial de avatar');

    final tutorialService = AvatarTutorialService();
    tutorialService.showTutorial(
      context: context,
      attachButtonKey: attachButtonKey,
      language: language,
      onFinish: () {
        debugPrint(
          '✅ [IaChatScreen] Tutorial completado, usuario puede interactuar',
        );
      },
    );
  }

  void _showVoiceNoteTutorial() {
    final chatInputState = _chatInputKey.currentState;
    if (chatInputState == null) {
      debugPrint('⚠️ [IaChatScreen] ChatInputWidget state no disponible');
      return;
    }

    final micButtonKey = chatInputState.micButtonKey;
    final language = context.read<RegisterCubit>().state.language ?? 'English';

    debugPrint('🎤 [IaChatScreen] Mostrando tutorial de voice note');

    final tutorialService = VoiceNoteTutorialService();
    tutorialService.showTutorial(
      context: context,
      micButtonKey: micButtonKey,
      language: language,
      onFinish: () {
        debugPrint('✅ [IaChatScreen] Tutorial de voice note completado');
      },
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
                              suggestions: List<String>.from(
                                message["options"],
                              ),
                              onSelected: (suggestion) {
                                _chatController.onSuggestionSelected(
                                  suggestion,
                                );
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
                  key: _chatInputKey, //  Ya estaba, perfecto
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
                        text:
                            "If you'd like to add images or audio, please use the app!",
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
                        text:
                            "If you'd like to add images or audio, please use the app!",
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
