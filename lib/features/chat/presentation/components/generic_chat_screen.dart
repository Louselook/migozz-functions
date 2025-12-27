import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/chat/controllers/generic_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';

/// Pantalla genérica de chat mejorada
/// Base reutilizable para diferentes tipos de chat (usuario-usuario, IA, etc.)
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
  final String? otherUserName;
  final String? otherUserAvatar;

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
    this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<GenericChatScreen> createState() => GenericChatScreenState();
}

class GenericChatScreenState extends State<GenericChatScreen> {
  final TextEditingController _textController = TextEditingController();
  late GlobalKey<ChatInputWidgetState> _chatInputKey;
  final bool _isInitialized = true;
  bool _isAtBottom = true;
  int _unreadMessagesCount = 0;
  int _previousMessagesCount = 0;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _chatInputKey = GlobalKey<ChatInputWidgetState>();
    _previousMessagesCount = widget.chatController.messages.length;

    // 🆕 Deshabilitar auto-scroll del controller para control manual
    widget.chatController.setAutoScroll(false);

    widget.chatController.scrollController.addListener(_onScrollChanged);
    widget.chatController.addListener(_onMessagesChanged);
  }

  @override
  void dispose() {
    widget.chatController.scrollController.removeListener(_onScrollChanged);
    widget.chatController.removeListener(_onMessagesChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    final scrollController = widget.chatController.scrollController;
    if (!scrollController.hasClients) return;

    if (_isProgrammaticScroll) return;

    final isAtBottom = scrollController.position.pixels <= 100;

    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });

      if (isAtBottom) {
        setState(() {
          _unreadMessagesCount = 0;
        });
      }
    }
  }

  void _onMessagesChanged() {
    final currentMessagesCount = widget.chatController.messages.length;

    if (currentMessagesCount > _previousMessagesCount) {
      final newMessages = currentMessagesCount - _previousMessagesCount;

      // 🔑 Verificar si el último mensaje es del otro usuario
      final lastMessage = widget.chatController.messages.last;
      final isReceivedMessage = lastMessage["other"] == true;

      // 🆕 Guardar posición ANTES de actualizar estado
      final scrollController = widget.chatController.scrollController;
      double? savedScrollPosition;
      double? savedMaxScrollExtent;

      if (scrollController.hasClients && !_isAtBottom && isReceivedMessage) {
        savedScrollPosition = scrollController.position.pixels;
        savedMaxScrollExtent = scrollController.position.maxScrollExtent;
        debugPrint(
          '💾 [GenericChat] Guardando posición: pixels=$savedScrollPosition, max=$savedMaxScrollExtent',
        );
      }

      debugPrint(
        '📨 [GenericChat] Nuevo mensaje detectado | isAtBottom: $_isAtBottom | isReceived: $isReceivedMessage | newMessages: $newMessages',
      );

      setState(() {
        _previousMessagesCount = currentMessagesCount;

        // 🔥 LÓGICA ACTUALIZADA:
        if (!isReceivedMessage) {
          // 👤 MENSAJE PROPIO → SIEMPRE hacer scroll automático
          debugPrint('✅ [GenericChat] Mensaje propio - Scroll automático');
          _isAtBottom = true;
          _scrollToBottom();
        } else {
          // 💬 MENSAJE RECIBIDO
          if (_isAtBottom) {
            debugPrint(
              '✅ [GenericChat] Mensaje recibido - Scroll automático (estaba en bottom)',
            );
            _scrollToBottom();
          } else {
            debugPrint(
              '🔴 [GenericChat] Mensaje recibido - Manteniendo posición de lectura',
            );
            _unreadMessagesCount += newMessages;

            // 🆕 Restaurar posición después del rebuild
            if (savedScrollPosition != null && savedMaxScrollExtent != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!scrollController.hasClients) return;

                // Calcular el desplazamiento causado por los nuevos mensajes
                final newMaxScrollExtent =
                    scrollController.position.maxScrollExtent;
                final scrollDelta = newMaxScrollExtent - savedMaxScrollExtent!;

                // Ajustar la posición para compensar el nuevo contenido
                // Con reverse:true, los nuevos mensajes se agregan "arriba" (position 0)
                // así que necesitamos ajustar la posición
                final targetPosition = savedScrollPosition! + scrollDelta;

                scrollController.jumpTo(targetPosition);

                debugPrint(
                  '📍 [GenericChat] Posición restaurada: $savedScrollPosition → $targetPosition (delta: $scrollDelta)',
                );
              });
            }
          }
        }
      });
    }
  }

  void _scrollToBottom() {
    _isProgrammaticScroll = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollController = widget.chatController.scrollController;
      if (!scrollController.hasClients) {
        _isProgrammaticScroll = false;
        return;
      }

      scrollController
          .animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) => _isProgrammaticScroll = false)
          .catchError((error) => _isProgrammaticScroll = false);
    });
  }

  void _onScrollToBottomPressed() {
    setState(() {
      _unreadMessagesCount = 0;
      _isAtBottom = true;
    });
    _scrollToBottom();
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
                            otherUserName: widget.otherUserName,
                            otherUserAvatar: widget.otherUserAvatar,
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
      // Botón flotante para scroll al bottom con contador
      floatingActionButton: !_isAtBottom
          ? Padding(
              padding: const EdgeInsets.only(bottom: 75, right: 4),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _onScrollToBottomPressed,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        // Badge circular más pequeño
                        if (_unreadMessagesCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadMessagesCount > 9
                                      ? '9+'
                                      : _unreadMessagesCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
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
