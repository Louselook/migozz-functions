import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/services/ai/assistant_functions.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/registration_handler.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/send_chat.dart';
import 'package:migozz_app/features/chat/presentation/register/components/suggestion_chips.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/chat_navigation_handler.dart';
import 'package:migozz_app/features/chat/presentation/components/generic_chat_screen.dart';
import 'package:migozz_app/features/tutorial/avatar_register_tutorial.dart';
import 'package:migozz_app/features/tutorial/voice_register_tutorial.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ChatInputWidgetState> chatInputKey = GlobalKey<ChatInputWidgetState>();
  late final RegisterChatController _chatController;
  bool _isCompletingRegistration = false;
  late GlobalKey<GenericChatScreenState> _genericChatKey;

  @override
  void initState() {
    super.initState();
    _genericChatKey = GlobalKey<GenericChatScreenState>();

    final authState = context.read<AuthCubit>().state;
    final firebaseUid = authState.firebaseUser?.uid;

    debugPrint('🔑 [IaChatScreen] Firebase UID: $firebaseUid');

    _chatController = RegisterChatController(
      registerCubit: context.read<RegisterCubit>(),
      firebaseUid: firebaseUid,
    );

    // Callbacks para gestionar el audio y tutoriales
    _chatController.onResetAudioUI = () {
      _genericChatKey.currentState?.resetAudioManager();
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
            SnackBar(
              content: Text("chat.validations.missingData".tr()),
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
              SnackBar(
                content: Text("chat.validations.missingEmailOTP".tr()),
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
          SnackBar(
            content: Text("${"chat.validations.errorCompleting".tr()}$e"),
          ),
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
    final attachButtonKey = _genericChatKey.currentState?.getAttachButtonKey();
    if (attachButtonKey == null) {
      debugPrint('⚠️ [IaChatScreen] Attach button key no disponible');
      return;
    }

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
    final micButtonKey = _genericChatKey.currentState?.getMicButtonKey();
    if (micButtonKey == null) {
      debugPrint('⚠️ [IaChatScreen] Mic button key no disponible');
      return;
    }

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

  void onSuggestionTap(dynamic option) async {
    final result = handleSuggestion(option);
    // Usa la instancia _chatController que ya creaste en initState
    switch (result.action) {
      case AssistantAction.openCamera:
        await chatInputKey.currentState?.openCameraFromSuggestions();
        break;

      case AssistantAction.openGallery:
        await chatInputKey.currentState?.openGalleryFromSuggestions();
        break;

      case AssistantAction.sendText:
        final text = result.payload ?? '';
        // Reutiliza el flujo existente en RegisterChatController
        // onSuggestionSelected ya existe y procesa el texto. Usalo.
        _chatController.onSuggestionSelected(text);
        break;

      case AssistantAction.skip:
        // Si tu controller tiene un método específico para skip, úsalo;
        // de lo contrario, envía la opción al mismo onSuggestionSelected
        // para que el flujo lo procese.
        _chatController.onSuggestionSelected('skip');
              break;

      case AssistantAction.unknown:
      debugPrint('Suggestion unknown or unhandled: ${result.payload}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericChatScreen(
      key: _genericChatKey,
      chatController: _chatController,
      backgroundColor: AppColors.backgroundDark,
      reverseMessages: true,
      showSuggestions: true,
      showLoading: false,
      passChatControllerToMessages: true,
      customAppBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: PrimaryText("chat.assistant.title".tr()),
        centerTitle: true,
      ),
      customInput: ListenableBuilder(
        listenable: _chatController,
        builder: (context, child) {
          return ChatInputWidget(
            key: chatInputKey,
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
            onSendAudio: (path) {
              if (kIsWeb) {
                sendChat(
                  other: false,
                  type: MessageType.text,
                  text: "chat.input.webRestriction".tr(),
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
            onSendImage: (path) {
              if (kIsWeb) {
                sendChat(
                  other: false,
                  type: MessageType.text,
                  text: "chat.input.webRestriction".tr(),
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
      suggestionBuilder: ListenableBuilder(
        listenable: _chatController,
        builder: (context, child) {
          final messages = _chatController.messages;
          if (messages.isEmpty) {
            return const SizedBox.shrink();
          }

          // Buscar el último mensaje del bot con opciones
          for (int i = messages.length - 1; i >= 0; i--) {
            final message = messages[i];
            if (message["other"] == true &&
                message["options"] != null &&
                (message["options"] as List).isNotEmpty) {
              final rawOptions = message["rawOptions"] as List? ?? message["options"] as List? ?? [];
              final labels = rawOptions.map((o) {
                if (o is String) return o;
                if (o is Map) return (o['label'] ?? o['text']).toString();
                return o.toString();
              }).toList(growable: false);

              return SuggestionChips(
                suggestions: List<String>.from(labels),
                onSelected: (selectedLabel) {
                  // Buscar el objeto original en rawOptions que coincida con el label
                  final matched = rawOptions.firstWhere(
                    (o) {
                      if (o is String) return o == selectedLabel;
                      if (o is Map) return ((o['label'] ?? o['text'])?.toString() ?? '') == selectedLabel;
                      return o.toString() == selectedLabel;
                    },
                    orElse: () => selectedLabel,
                  );
                  onSuggestionTap(matched); // ahora pasamos el mapa original o el string
                },
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
