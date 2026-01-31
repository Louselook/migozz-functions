// user_chat_screen.dart - VERSIÓN CON TRADUCCIONES
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/services/notifications/active_chat_manager.dart';

import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/chat/controllers/user_chat_controller.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/datasources/message_adapter.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';
import 'package:migozz_app/features/chat/presentation/components/generic_chat_screen.dart';

/// Pantalla de chat entre dos usuarios
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
  late UserChatController _chatController;
  late String _chatRoomId;
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  bool _isInitialized = false;
  bool _isBlocked = false; // Current user blocked the other user
  bool _isBlockedByOther = false; // Current user was blocked by the other user
  StreamSubscription? _messagesSubscription;
  late GlobalKey<GenericChatScreenState> _genericChatKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _genericChatKey = GlobalKey<GenericChatScreenState>();

    _chatController = UserChatController(
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
      otherUserName: widget.otherUserName,
      otherUserAvatar: widget.otherUserAvatar,
      onSendToBackend: _sendMessageToBackend,
      onMarkAsRead: _markMessageAsRead,
    );

    _chatController.setAutoScroll(false);

    _initializeChat();
  }

  @override
  void dispose() {
    // Leave the active chat to allow notifications again
    ActiveChatManager.instance.leaveChat();

    _messagesSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
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

      // Register this chat as active to suppress notifications
      ActiveChatManager.instance.enterChat(
        otherUserId: widget.otherUserId,
        chatRoomId: _chatRoomId,
      );

      _loadMessages();

      await _markAllAsReadSilently();

      // Check if current user blocked the other user
      _isBlocked = await _chatService.isUserBlocked(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      // Check if current user was blocked by the other user
      _isBlockedByOther = await _chatService.isBlockedByOtherUser(
        chatRoomId: _chatRoomId,
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ [UserChat] Error al inicializar: $e');
    }
  }

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
            if (!mounted) return;

            _chatController.clearMessages();

            final uiMessages = MessageAdapter.toUiMessages(
              firestoreMessages.reversed.toList(),
              widget.currentUserId,
            );

            if (uiMessages.isNotEmpty) {
              _chatController.addMessages(uiMessages);
            }

            _markNewMessagesAsRead(firestoreMessages);
          },
          onError: (error) {
            debugPrint('❌ [UserChat] Error al cargar mensajes: $error');
          },
        );
  }

  Future<void> _markNewMessagesAsRead(List<dynamic> messages) async {
    try {
      for (final msg in messages) {
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
            content: Text("${"chat.userChat.errors.sendMessage".tr()}$e"),
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

  Future<void> _goToProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.otherUserId)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("chat.userChat.errors.profileNotFound".tr()),
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
            content: Text("${"chat.userChat.errors.loadProfile".tr()}$e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "chat.userChat.dialogs.deleteTitle".tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "chat.userChat.dialogs.deleteMessage".tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "chat.userChat.dialogs.cancel".tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "chat.userChat.dialogs.delete".tr(),
              style: const TextStyle(color: Colors.red),
            ),
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
            SnackBar(
              content: Text("chat.userChat.messages.chatDeleted".tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('❌ [UserChat] Error al eliminar chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${"chat.userChat.errors.deleteChat".tr()}$e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleBlockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isBlocked
              ? "chat.userChat.dialogs.unblockTitle".tr(
                  namedArgs: {'name': widget.otherUserName},
                )
              : "chat.userChat.dialogs.blockTitle".tr(
                  namedArgs: {'name': widget.otherUserName},
                ),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _isBlocked
              ? "chat.userChat.dialogs.unblockMessage".tr()
              : "chat.userChat.dialogs.blockMessage".tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "chat.userChat.dialogs.cancel".tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _isBlocked
                  ? "chat.userChat.dialogs.unblock".tr()
                  : "chat.userChat.dialogs.block".tr(),
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
                    ? "chat.userChat.messages.userBlocked".tr(
                        namedArgs: {'name': widget.otherUserName},
                      )
                    : "chat.userChat.messages.userUnblocked".tr(
                        namedArgs: {'name': widget.otherUserName},
                      ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ [UserChat] Error al bloquear/desbloquear: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${"chat.userChat.errors.blockUser".tr()}$e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reportController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "chat.userChat.dialogs.reportTitle".tr(
            namedArgs: {'name': widget.otherUserName},
          ),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reportController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "chat.userChat.dialogs.reportHint".tr(),
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "chat.userChat.dialogs.cancel".tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reportController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              "chat.userChat.dialogs.reportSubmit".tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && reportController.text.trim().isNotEmpty) {
      try {
        await _chatService.reportUser(
          reporterId: widget.currentUserId,
          reportedUserId: widget.otherUserId,
          chatRoomId: _chatRoomId,
          reason: reportController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("chat.userChat.dialogs.reportSuccess".tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ [UserChat] Error al reportar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${"chat.userChat.dialogs.reportError".tr()}$e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reportController.dispose();
  }

  Future<void> _sendAudioMessage(String audioPath) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("chat.userChat.webRestrictions.audio".tr()),
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
        'time': "chat.userChat.messages.sending".tr(),
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
            content: Text("${"chat.userChat.errors.sendAudio".tr()}$e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("chat.userChat.webRestrictions.image".tr()),
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
          {'imageUrl': imagePath, 'label': "chat.userChat.messages.image".tr()},
        ],
        'time': "chat.userChat.messages.sending".tr(),
        'senderName': "chat.userChat.messages.you".tr(),
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
            content: Text("${"chat.userChat.errors.sendImage".tr()}$e"),
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

    return GenericChatScreen(
      key: _genericChatKey,
      chatController: _chatController,
      backgroundColor: AppColors.backgroundDark,
      reverseMessages: true,
      showSuggestions: false,
      showLoading: false,
      customAppBar: _buildAppBar(),
      otherUserName: widget.otherUserName,
      otherUserAvatar: widget.otherUserAvatar,
      customInput: _buildCustomInput(),
    );
  }

  /// Build the custom input widget based on block status
  Widget _buildCustomInput() {
    // If current user was blocked by the other user, show blocked indicator
    if (_isBlockedByOther) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              "chat.userChat.messages.youAreBlocked".tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // If current user blocked the other user, show unblock button
    if (_isBlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              "chat.userChat.messages.unblockToChat".tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _toggleBlockUser,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x33008000), // Green with 20% opacity
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                "chat.userChat.dialogs.unblock".tr(),
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    // Normal input widget
    return ChatInputWidget(
      controller: _textController,
      onSend: () {
        if (_textController.text.trim().isNotEmpty) {
          _chatController.sendTextMessage(_textController.text);
          _textController.clear();
        }
      },
      onSendAudio: _sendAudioMessage,
      onSendImage: _sendImageMessage,
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
        onTap: _goToProfile,
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
                      if (_isBlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.block, color: Colors.red, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    "chat.userChat.appBar.tapToViewProfile".tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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

              case 'delete':
                _deleteChat();
                break;
              case 'block':
                _toggleBlockUser();
                break;
              case 'report':
                _showReportDialog();
                break;
            }
          },
          itemBuilder: (context) => [

            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    "chat.userChat.menu.deleteChat".tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
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
                    _isBlocked
                        ? "chat.userChat.menu.unblock".tr()
                        : "chat.userChat.menu.block".tr(),
                    style: TextStyle(
                      color: _isBlocked ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    "chat.userChat.menu.report".tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
