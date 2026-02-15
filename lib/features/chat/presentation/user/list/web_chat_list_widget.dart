import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_list_item.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebChatListWidget extends StatefulWidget {
  final String username;
  final String currentUserId;
  final VoidCallback? onClose;

  const WebChatListWidget({
    super.key,
    required this.username,
    required this.currentUserId,
    this.onClose,
    this.onChatSelected,
  });

  final Function(ChatPreview)? onChatSelected;

  @override
  State<WebChatListWidget> createState() => _WebChatListWidgetState();
}

class _WebChatListWidgetState extends State<WebChatListWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<ChatPreview?> _chatRoomToPreview(ChatRoom chatRoom) async {
    try {
      final otherUserId = chatRoom.getOtherParticipant(widget.currentUserId);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: otherUserId)
          .limit(1)
          .get();
      if (userDoc.docs.isEmpty) return null;
      final userData = userDoc.docs.first.data();

      return ChatPreview(
        userId: otherUserId,
        displayName: userData['displayName'] ?? 'Usuario',
        username: userData['userName'] ?? userData['username'] ?? 'user',
        avatarUrl: userData['avatarUrl'],
        lastMessage: chatRoom.lastMessage ?? 'Nuevo chat',
        timeAgo: _formatTime(chatRoom.lastMessageTime),
        isVerified: userData['isVerified'] ?? false,
        isOnline: false,
        unreadCount: chatRoom.getUnreadCount(widget.currentUserId),
        isBlocked: chatRoom.isBlocked(widget.currentUserId, otherUserId),
      );
    } catch (e) {
      debugPrint('Error converting ChatRoom: $e');
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${difference.inDays ~/ 7}w';
  }

  List<ChatPreview> _filterChats(List<ChatPreview> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats
        .where(
          (chat) =>
              chat.displayName.toLowerCase().contains(_searchQuery) ||
              chat.username.toLowerCase().contains(_searchQuery) ||
              chat.lastMessage.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onClose != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                  ),
              ],
            ),
          ),
          _buildSearchBar(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatStream(isActive: true),
                _buildChatStream(isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatStream({required bool isActive}) {
    final stream = isActive
        ? _chatService.getActiveChatsStream(widget.currentUserId)
        : _chatService.getNewChatsStream(widget.currentUserId);
    return StreamBuilder<List<ChatRoom>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          );
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
            'Oops! Algo salió mal',
            icon: Icons.error_outline,
          );
        }
        final chatRooms = snapshot.data ?? [];
        if (chatRooms.isEmpty) {
          return _buildEmptyState(
            isActive ? 'No messages yet' : 'No new messages',
          );
        }

        final unreadKey = chatRooms
            .map(
              (r) =>
                  '${r.chatRoomId}:${r.getUnreadCount(widget.currentUserId)}',
            )
            .join('_');

        return FutureBuilder<List<ChatPreview?>>(
          key: ValueKey(unreadKey),
          future: Future.wait(
            chatRooms.map((room) => _chatRoomToPreview(room)),
          ),
          builder: (context, previewSnapshot) {
            if (!previewSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E63)),
              );
            }
            final filteredChats = _filterChats(
              previewSnapshot.data!
                  .where((p) => p != null)
                  .cast<ChatPreview>()
                  .toList(),
            );
            if (filteredChats.isEmpty) {
              return _buildEmptyState('No results found');
            }
            return _buildChatList(filteredChats);
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "profile.chat.search".tr(),
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(child: Center(child: Text('Chat'))),
                  Tab(child: Center(child: Text("profile.chat.filter".tr()))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatPreview> chats) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          onTap: () {
            if (widget.onChatSelected != null) {
              widget.onChatSelected!(chat);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserChatScreen(
                    otherUserId: chat.userId,
                    otherUserName: chat.displayName,
                    otherUserAvatar: chat.avatarUrl,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, {IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
