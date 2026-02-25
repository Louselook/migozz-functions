import 'dart:async';

import 'package:flutter/material.dart';
import 'package:migozz_app/core/services/notifications/active_chat_manager.dart';
import 'package:migozz_app/features/chat/controllers/user_chat_controller.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/datasources/message_adapter.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/chat_input_widget.dart';
import 'package:migozz_app/features/chat/presentation/components/generic_chat_screen.dart';

class WebUserChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String currentUserId;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const WebUserChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.currentUserId,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<WebUserChatScreen> createState() => _WebUserChatScreenState();
}

class _WebUserChatScreenState extends State<WebUserChatScreen>
    with WidgetsBindingObserver {
  late UserChatController _chatController;
  late String _chatRoomId;
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  bool _isInitialized = false;
  bool _isBlocked = false;
  bool _isBlockedByOther = false;
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
      _chatRoomId = await _chatService.getOrCreateChatRoom(
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      ActiveChatManager.instance.enterChat(
        otherUserId: widget.otherUserId,
        chatRoomId: _chatRoomId,
      );

      _loadMessages();
      await _markAllAsReadSilently();

      _isBlocked = await _chatService.isUserBlocked(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      _isBlockedByOther = await _chatService.isBlockedByOtherUser(
        chatRoomId: _chatRoomId,
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ [WebUserChat] Error: $e');
    }
  }

  Future<void> _markAllAsReadSilently() async {
    try {
      await _chatService.markAllMessagesAsRead(
        chatRoomId: _chatRoomId,
        userId: widget.currentUserId,
      );
    } catch (e) {
      debugPrint('❌ [WebUserChat] Error marking read: $e');
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
            debugPrint('❌ [WebUserChat] Load messages error: $error');
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
      debugPrint('❌ [WebUserChat] Error marking new read: $e');
    }
  }

  Future<void> _sendMessageToBackend(String message) async {
    try {
      await _chatService.sendTextMessage(
        chatRoomId: _chatRoomId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        text: message,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sending message: $e")));
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
      debugPrint('❌ [WebUserChat] Error marking read: $e');
    }
  }

  Future<void> _toggleBlockUser() async {
    // Simplified block logic for Web
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
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3F1944), // Purple dark
              Color(0xFF0D0D11), // Almost black
              Color(0xFF2E200D), // Gold dark
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3F1944), // Purple dark
            Color(0xFF0D0D11), // Almost black
            Color(0xFF2E200D), // Gold dark
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: GenericChatScreen(
        key: _genericChatKey,
        chatController: _chatController,
        backgroundColor: Colors.transparent, // Transparent to show gradient
        reverseMessages: true,
        showSuggestions: false,
        showLoading: false,
        customAppBar: _buildAppBar(),
        otherUserName: widget.otherUserName,
        otherUserAvatar: widget.otherUserAvatar,
        customInput: _buildCustomInput(),
      ),
    );
  }

  Widget _buildCustomInput() {
    if (_isBlockedByOther) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black54,
        child: const Center(
          child: Text(
            "You are blocked",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_isBlocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("User blocked", style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _toggleBlockUser,
              child: const Text(
                "Unblock",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return ChatInputWidget(
      controller: _textController,
      onSend: () {
        if (_textController.text.trim().isNotEmpty) {
          _chatController.sendTextMessage(_textController.text);
          _textController.clear();
        }
      },
      // Web doesn't support audio/image upload easily yet in this simplified view
      onSendAudio: (path) {},
      onSendImage: (path) {},
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(
        255,
        0,
        0,
        0,
      ), // Dark purplish/black for header
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBack,
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
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
          const SizedBox(width: 10),
          Expanded(
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
        ],
      ),
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: widget.onClose, // Keep function, change icon
            iconSize: 20,
          ),
        ),
      ],
    );
  }
}
