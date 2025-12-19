import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/chat/controllers/generic_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';

/// Pantalla genérica de chat mejorada
/// Base reutilizable para diferentes tipos de chat (usuario-usuario, IA, etc.)
/// Incluye soporte para:
/// - Renderizado inverso de mensajes (nuevos abajo)
/// - Manejo de sugerencias/opciones
/// - Input personalizado o por defecto
/// - Mensajes de audio e imágenes
/// - Recuperación de errores
class GenericChatScreen extends StatefulWidget {
  final GenericChatController chatController;
  final String? title;
  final Widget? customAppBar;
  final Widget? customInput;
  final bool showDefaultInput;
  final Color? backgroundColor;
  final bool reverseMessages;
  final bool showSuggestions;
  final Function(String)? onSugestionSelected;
  final Widget? suggestionBuilder;
  final VoidCallback? onMessageAdded;
  final bool showLoading;
  final bool passChatControllerToMessages;

  const GenericChatScreen({
    super.key,
    required this.chatController,
    this.title,
    this.customAppBar,
    this.customInput,
    this.showDefaultInput = true,
    this.backgroundColor,
    this.reverseMessages = true,
    this.showSuggestions = false,
    this.onSugestionSelected,
    this.suggestionBuilder,
    this.onMessageAdded,
    this.showLoading = false,
    this.passChatControllerToMessages = false,
  });

  @override
  State<GenericChatScreen> createState() => GenericChatScreenState();
}

class GenericChatScreenState extends State<GenericChatScreen> {
  final TextEditingController _textController = TextEditingController();
  late GlobalKey<ChatInputWidgetState> _chatInputKey;
  bool _isInitialized = true;

  @override
  void initState() {
    super.initState();
    _chatInputKey = GlobalKey<ChatInputWidgetState>();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.chatController.sendTextMessage(text);
    _textController.clear();
    widget.onMessageAdded?.call();
  }

  /// Resetea el audio manager del ChatInputWidget
  void resetAudioManager() {
    if (_chatInputKey.currentState != null) {
      _chatInputKey.currentState?.resetAudioManager();
    }
  }

  /// Obtiene la clave del botón de archivos adjuntos
  GlobalKey? getAttachButtonKey() {
    return _chatInputKey.currentState?.attachButtonKey;
  }

  /// Obtiene la clave del botón de micrófono
  GlobalKey? getMicButtonKey() {
    return _chatInputKey.currentState?.micButtonKey;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLoading && !_isInitialized) {
      return Scaffold(
        backgroundColor: widget.backgroundColor ?? AppColors.backgroundDark,
        appBar: widget.customAppBar != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: widget.customAppBar!,
              )
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: widget.title != null
                    ? PrimaryText(widget.title!)
                    : const PrimaryText("Chat"),
                centerTitle: true,
              ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.backgroundDark,
      appBar: widget.customAppBar != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: widget.customAppBar!,
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: widget.title != null
                  ? PrimaryText(widget.title!)
                  : const PrimaryText("Chat"),
              centerTitle: true,
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Lista de mensajes
            Expanded(
              child: ListenableBuilder(
                listenable: widget.chatController,
                builder: (context, child) {
                  final messages = widget.chatController.messages;
                  return ListView.builder(
                    controller: widget.chatController.scrollController,
                    padding: const EdgeInsets.all(10),
                    reverse: widget.reverseMessages,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Invertir índice si reverse es true
                      final messageIndex = widget.reverseMessages
                          ? messages.length - 1 - index
                          : index;
                      final message = messages[messageIndex];

                      // Verificar si es último mensaje con opciones
                      final isLastBotMsgWithOptions =
                          widget.showSuggestions &&
                          message["other"] == true &&
                          (message["options"] != null &&
                              (message["options"] as List).isNotEmpty) &&
                          !messages
                              .sublist(messageIndex + 1)
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
                            chatController: widget.passChatControllerToMessages
                                ? widget.chatController
                                : null,
                          ),
                          // Mostrar sugerencias si existe el builder
                          if (isLastBotMsgWithOptions &&
                              widget.suggestionBuilder != null)
                            widget.suggestionBuilder!
                          else if (isLastBotMsgWithOptions &&
                              widget.onSugestionSelected != null)
                            _buildDefaultSuggestions(
                              List<String>.from(message["options"]),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input personalizado o por defecto
            if (widget.customInput != null)
              widget.customInput!
            else if (widget.showDefaultInput)
              _buildDefaultInput(),
          ],
        ),
      ),
    );
  }

  /// Constructor por defecto para mostrar sugerencias
  Widget _buildDefaultSuggestions(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: suggestions.map((suggestion) {
          return ActionChip(
            onPressed: () => widget.onSugestionSelected?.call(suggestion),
            label: Text(suggestion),
            backgroundColor: const Color(0xFF2C2C2E),
            labelStyle: const TextStyle(color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Escribe un mensaje...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 48,
            width: 50,
            decoration: BoxDecoration(
              gradient: AppColors.verticalPinkPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
