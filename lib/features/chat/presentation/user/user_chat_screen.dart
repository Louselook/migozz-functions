import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/chat/controllers/user_chat_controller.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/datasources/message_adapter.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';

/// Pantalla de chat entre dos usuarios con ChatInputWidget completo
class UserChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String currentUserId;

  const UserChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.currentUserId,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late UserChatController _chatController;
  late String _chatRoomId;
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _chatController = UserChatController(
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
      otherUserName: widget.otherUserName,
      otherUserAvatar: widget.otherUserAvatar,
      onSendToBackend: _sendMessageToBackend,
      onMarkAsRead: _markMessageAsRead,
    );

    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      debugPrint(
        '📥 [UserChat] Inicializando chat con ${widget.otherUserName}',
      );

      _chatRoomId = await _chatService.getOrCreateChatRoom(
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      _loadMessages();

      await _chatService.markAllMessagesAsRead(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ [UserChat] Error al inicializar: $e');
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    _chatService
        .getMessagesStream(_chatRoomId)
        .listen(
          (firestoreMessages) {
            _chatController.clearMessages();

            final uiMessages = MessageAdapter.toUiMessages(
              firestoreMessages.reversed.toList(),
              widget.currentUserId,
            );

            if (uiMessages.isNotEmpty) {
              _chatController.addMessages(uiMessages);
            }
          },
          onError: (error) {
            debugPrint('❌ [UserChat] Error al cargar mensajes: $error');
          },
        );
  }

  Future<void> _sendMessageToBackend(String message) async {
    try {
      debugPrint('📤 [UserChat] Enviando mensaje a ${widget.otherUserName}');

      await _chatService.sendTextMessage(
        chatRoomId: _chatRoomId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        text: message,
      );

      debugPrint('✅ [UserChat] Mensaje enviado: $message');
    } catch (e) {
      debugPrint('❌ [UserChat] Error al enviar mensaje: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    try {
      await _chatService.markMessageAsRead(
        chatRoomId: _chatRoomId,
        messageId: messageId,
      );
    } catch (e) {
      debugPrint('❌ [UserChat] Error al marcar como leído: $e');
    }
  }

  // Enviar audio - CORREGIDO
  Future<void> _sendAudioMessage(String audioPath) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please use the app to send audio!"),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    try {
      debugPrint('🎤 [UserChat] Enviando audio a ${widget.otherUserName}');

      // Agregar mensaje visual inmediatamente (TUYO)
      _chatController.addMessage({
        'other': false, // TÚ lo enviaste
        'type': MessageType.audio, //  CRÍTICO: audioPlayback, NO audio
        'audio': audioPath,
        'time': 'Enviando...',
        'chatController': _chatController,
      });

      // Enviar a Firebase
      await _chatService.sendAudioMessage(
        chatRoomId: _chatRoomId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        audioFile: File(audioPath),
        durationSeconds: 0, // Se calculará en el servicio
      );

      debugPrint('✅ [UserChat] Audio enviado');
    } catch (e) {
      debugPrint('❌ [UserChat] Error al enviar audio: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Enviar imagen - MEJORADO
  Future<void> _sendImageMessage(String imagePath) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please use the app to send images!"),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    try {
      debugPrint('📸 [UserChat] Enviando imagen a ${widget.otherUserName}');

      // Agregar mensaje visual con información del usuario
      _chatController.addMessage({
        'other': false,
        'type': MessageType.pictureCard,
        'pictures': [
          {'imageUrl': imagePath, 'label': 'Imagen'},
        ],
        'time': 'Enviando...',
        'senderName': 'Tú', //  Info del remitente
        'senderAvatar': null,
      });

      // Enviar a Firebase
      await _chatService.sendImageMessage(
        chatRoomId: _chatRoomId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        imageFiles: [File(imagePath)],
      );

      debugPrint('✅ [UserChat] Imagen enviada');
    } catch (e) {
      debugPrint('❌ [UserChat] Error al enviar imagen: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Lista de mensajes
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
                    return ChatMessageBuilder.buildMessage(
                      message,
                      chatController: null,
                      // Pasar info del otro usuario
                      otherUserName: widget.otherUserName,
                      otherUserAvatar: widget.otherUserAvatar,
                    );
                  },
                );
              },
            ),
          ),

          // Input con audio e imágenes
          ChatInputWidget(
            controller: _textController,
            onSend: () {
              if (_textController.text.trim().isNotEmpty) {
                _chatController.sendTextMessage(_textController.text);
                _textController.clear();
              }
            },
            onSendAudio: _sendAudioMessage,
            onSendImage: _sendImageMessage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.otherUserAvatar?.isNotEmpty == true
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            backgroundColor: Colors.grey[800],
            child: widget.otherUserAvatar?.isEmpty ?? true
                ? Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Nombre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Toca para ver perfil",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                debugPrint('👤 Ver perfil de ${widget.otherUserName}');
                break;
              case 'delete':
                debugPrint('👤 Eliminar perfil de ${widget.otherUserName}');
                break;
              case 'block':
                debugPrint('🚫 Bloquear a ${widget.otherUserName}');
                break;
              case 'report':
                debugPrint('⚠️ Reportar a ${widget.otherUserName}');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Ver perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Eliminar chat', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 12),
                  Text('Bloquear'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 20),
                  SizedBox(width: 12),
                  Text('Reportar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
