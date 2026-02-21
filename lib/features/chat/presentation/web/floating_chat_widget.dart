import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';
import 'package:migozz_app/features/chat/presentation/web/web_user_chat_screen.dart';
import 'package:migozz_app/features/chat/presentation/web/web_chat_controller.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/chat/presentation/user/list/web_chat_list_widget.dart';

class FloatingChatWidget extends StatefulWidget {
  const FloatingChatWidget({super.key});

  @override
  State<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends State<FloatingChatWidget> {
  ChatPreview? _activeChat;
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // No initialization needed here as we use BlocBuilder
  }

  void _openChat(ChatPreview chat) {
    setState(() {
      _activeChat = chat;
    });
    // Ensure it's expanded when a chat is opened
    WebChatController().open();
  }

  void _backToList() {
    setState(() {
      _activeChat = null;
    });
  }

  void _toggleExpand() {
    WebChatController().toggle();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.userProfile;
        if (user == null || user.email.isEmpty) return const SizedBox.shrink();

        _currentUserId = user.email;

        return ValueListenableBuilder<bool>(
          valueListenable: WebChatController().isOpenNotifier,
          builder: (context, isExpanded, child) {
            // If collapsed, reset active chat? Maybe not, better to keep state.
            // But if user closes it, maybe reset? Let's keep it simple.

            return Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Container (List or Chat)
                  if (isExpanded)
                    Container(
                      width: 380,
                      height: 550,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _activeChat != null
                            ? _buildChatDetail()
                            : _buildChatList(),
                      ),
                    ),

                  // Toggle Button / Minimized Bar
                  // Toggle Button / Minimized Bar
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => WebChatController().toggle(),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isExpanded)
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              )
                            else ...[
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Mensajes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              // Optional: Add unread badge here
                              _buildUnreadBadge(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUnreadBadge() {
    if (_currentUserId == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: _chatService.getTotalUnreadCountStream(_currentUserId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFE91E63),
            shape: BoxShape.circle,
          ),
          child: Text(
            snapshot.data.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return WebChatListWidget(
      username:
          _currentUserId ??
          'User', // Should pass username if available, but ID is critical
      currentUserId: _currentUserId ?? '',
      onClose: _toggleExpand,
      onChatSelected: _openChat,
    );
  }

  Widget _buildChatDetail() {
    if (_activeChat == null || _currentUserId == null) {
      return const SizedBox.shrink();
    }

    return WebUserChatScreen(
      otherUserId: _activeChat!.userId,
      otherUserName: _activeChat!.displayName,
      otherUserAvatar: _activeChat!.avatarUrl,
      currentUserId: _currentUserId!,
      onBack: _backToList,
      onClose: _toggleExpand,
    );
  }
}
