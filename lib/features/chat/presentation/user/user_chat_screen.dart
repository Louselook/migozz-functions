// user_chat_screen.dart - VERSIÓN CON SOLO LA MEJORA DE MARCADO COMO LEÍDO
// Este archivo solo incluye los cambios necesarios para arreglar el problema de los mensajes no leídos

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_message_builder.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/chat/controllers/user_chat_controller.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/datasources/message_adapter.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';

/// Pantalla de chat entre dos usuarios - SOLO CON MEJORA DE MARCADO LEÍDO
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

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  // 🆕 AÑADIDO para detectar lifecycle
  late UserChatController _chatController;
  late String _chatRoomId;
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  bool _isInitialized = false;
  bool _isBlocked = false; // 🆕 Estado de bloqueo
  StreamSubscription? _messagesSubscription; // 🆕 Para cancelar el stream

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🆕 AÑADIDO

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

  @override
  void dispose() {
    _messagesSubscription?.cancel(); // 🆕 Cancelar stream PRIMERO
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 🆕 NUEVO: Detectar cuando la app vuelve del background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Marcar mensajes como leídos cuando la app vuelve a primer plano
      _markAllAsReadSilently();
    }
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

      // 🆕 CRÍTICO: Marcar todos los mensajes como leídos al entrar al chat
      await _markAllAsReadSilently();

      // 🆕 Verificar si el usuario está bloqueado
      _isBlocked = await _chatService.isUserBlocked(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ [UserChat] Error al inicializar: $e');
    }
  }

  /// 🆕 NUEVO: Marcar todos como leídos sin mostrar mensajes
  Future<void> _markAllAsReadSilently() async {
    try {
      await _chatService.markAllMessagesAsRead(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
      );
      debugPrint('✅ [UserChat] Todos los mensajes marcados como leídos');
    } catch (e) {
      debugPrint('❌ [UserChat] Error al marcar mensajes: $e');
    }
  }

  void _loadMessages() {
    _messagesSubscription = _chatService
        .getMessagesStreamForUser(
          chatRoomId: _chatRoomId,
          userId: widget.currentUserId,
        )
        .listen(
          (firestoreMessages) {
            // 🆕 Verificar que el widget esté montado antes de usar el controller
            if (!mounted) return;

            _chatController.clearMessages();

            final uiMessages = MessageAdapter.toUiMessages(
              firestoreMessages.reversed.toList(),
              widget.currentUserId,
            );

            if (uiMessages.isNotEmpty) {
              _chatController.addMessages(uiMessages);
            }

            // 🆕 NUEVO: Marcar nuevos mensajes como leídos automáticamente
            _markNewMessagesAsRead(firestoreMessages);
          },
          onError: (error) {
            debugPrint('❌ [UserChat] Error al cargar mensajes: $error');
          },
        );
  }

  /// 🆕 NUEVO: Marcar nuevos mensajes recibidos como leídos
  Future<void> _markNewMessagesAsRead(List<dynamic> messages) async {
    try {
      for (final msg in messages) {
        // Solo marcar como leídos los mensajes que recibí y que no están leídos
        if (msg.receiverId == widget.currentUserId && !msg.isRead) {
          await _chatService.markMessageAsRead(
            chatRoomId: _chatRoomId,
            messageId: msg.messageId,
            userId: widget.currentUserId,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [UserChat] Error al marcar nuevos mensajes: $e');
    }
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
        userId: widget.currentUserId,
      );
    } catch (e) {
      debugPrint('❌ [UserChat] Error al marcar como leído: $e');
    }
  }

  // ==================== ACCIONES DEL MENÚ ====================

  /// 🆕 Navegar al perfil del usuario
  Future<void> _goToProfile() async {
    try {
      // Buscar el usuario por email
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.otherUserId)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo encontrar el perfil del usuario'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userData = userDoc.docs.first.data();
      final user = UserDTO.fromMap({...userData, 'id': userDoc.docs.first.id});

      if (mounted) {
        context.push('/profile-view', extra: user);
      }
    } catch (e) {
      debugPrint('❌ [UserChat] Error al ir al perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🆕 Eliminar chat (solo para el usuario actual)
  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar chat?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'El chat se eliminará solo para ti. El otro usuario podrá seguir viéndolo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteChatForUser(
          chatRoomId: _chatRoomId,
          userId: widget.currentUserId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Volver a la lista de chats
        }
      } catch (e) {
        debugPrint('❌ [UserChat] Error al eliminar chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 🆕 Bloquear/Desbloquear usuario
  Future<void> _toggleBlockUser() async {
    final action = _isBlocked ? 'desbloquear' : 'bloquear';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿${_isBlocked ? 'Desbloquear' : 'Bloquear'} a ${widget.otherUserName}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _isBlocked
              ? 'Volverás a recibir mensajes de este usuario.'
              : 'No recibirás mensajes de este usuario mientras esté bloqueado. El usuario no sabrá que lo bloqueaste.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _isBlocked ? 'Desbloquear' : 'Bloquear',
              style: TextStyle(color: _isBlocked ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_isBlocked) {
          await _chatService.unblockUser(
            chatRoomId: _chatRoomId,
            userId: widget.currentUserId,
            blockedUserId: widget.otherUserId,
          );
        } else {
          await _chatService.blockUser(
            chatRoomId: _chatRoomId,
            userId: widget.currentUserId,
            blockedUserId: widget.otherUserId,
          );
        }

        setState(() {
          _isBlocked = !_isBlocked;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isBlocked
                    ? '${widget.otherUserName} ha sido bloqueado'
                    : '${widget.otherUserName} ha sido desbloqueado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ [UserChat] Error al $action usuario: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al $action: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // TODO: Implementar funcionalidad de reportar usuario
  // Future<void> _reportUser() async {
  //   // Implementar lógica de reporte
  // }

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

      _chatController.addMessage({
        'other': false,
        'type': MessageType.audio,
        'audio': audioPath,
        'time': 'Enviando...',
        'chatController': _chatController,
      });

      await _chatService.sendAudioMessage(
        chatRoomId: _chatRoomId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        audioFile: File(audioPath),
        durationSeconds: 0,
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

      _chatController.addMessage({
        'other': false,
        'type': MessageType.pictureCard,
        'pictures': [
          {'imageUrl': imagePath, 'label': 'Imagen'},
        ],
        'time': 'Enviando...',
        'senderName': 'Tú',
        'senderAvatar': null,
      });

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
          Expanded(
            child: ListenableBuilder(
              listenable: _chatController,
              builder: (context, child) {
                final messages = _chatController.messages;
                return ListView.builder(
                  controller: _chatController.scrollController,
                  padding: const EdgeInsets.all(10),
                  reverse: true, // 🆕 Los mensajes nuevos aparecen abajo
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // 🆕 Invertir el índice porque reverse: true
                    final reversedIndex = messages.length - 1 - index;
                    final message = messages[reversedIndex];
                    return ChatMessageBuilder.buildMessage(
                      message,
                      chatController: null,
                      otherUserName: widget.otherUserName,
                      otherUserAvatar: widget.otherUserAvatar,
                    );
                  },
                );
              },
            ),
          ),

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
      title: GestureDetector(
        onTap: _goToProfile, // 🆕 Tap en el título para ir al perfil
        child: Row(
          children: [
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 🆕 Indicador de bloqueado
                      if (_isBlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.block, color: Colors.red, size: 14),
                      ],
                    ],
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
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF2C2C2E),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _goToProfile();
                break;
              case 'delete':
                _deleteChat();
                break;
              case 'block':
                _toggleBlockUser();
                break;
              // TODO: Implementar reportar
              // case 'report':
              //   _reportUser();
              //   break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Ver perfil', style: TextStyle(color: Colors.white)),
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
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    _isBlocked ? Icons.check_circle : Icons.block,
                    size: 20,
                    color: _isBlocked ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isBlocked ? 'Desbloquear' : 'Bloquear',
                    style: TextStyle(
                      color: _isBlocked ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            // TODO: Habilitar cuando se implemente la funcionalidad de reportar
            // const PopupMenuItem(
            //   value: 'report',
            //   child: Row(
            //     children: [
            //       Icon(Icons.flag, size: 20, color: Colors.white),
            //       SizedBox(width: 12),
            //       Text('Reportar', style: TextStyle(color: Colors.white)),
            //     ],
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
