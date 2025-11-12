import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/chat/controllers/generic_chat_controller.dart';

/// Pantalla genérica de chat
/// Puede ser usada para diferentes tipos de chat (usuario-usuario, IA, etc.)
class GenericChatScreen extends StatefulWidget {
  final GenericChatController chatController;
  final String? title;
  final Widget? customAppBar;
  final Widget? customInput;
  final bool showDefaultInput;
  final Color? backgroundColor;

  const GenericChatScreen({
    super.key,
    required this.chatController,
    this.title,
    this.customAppBar,
    this.customInput,
    this.showDefaultInput = true,
    this.backgroundColor,
  });

  @override
  State<GenericChatScreen> createState() => _GenericChatScreenState();
}

class _GenericChatScreenState extends State<GenericChatScreen> {
  final TextEditingController _textController = TextEditingController();

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
  }

  @override
  Widget build(BuildContext context) {
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
                  return ListView.builder(
                    controller: widget.chatController.scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.chatController.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.chatController.messages[index];
                      return ChatMessageBuilder.buildMessage(
                        message,
                        chatController: widget.chatController,
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
