import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_tab.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_list_item.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla de lista de chats - VERSIÓN FINAL
class ChatsListScreen extends StatefulWidget {
  final String username;
  final String currentUserId;

  const ChatsListScreen({
    super.key,
    required this.username,
    required this.currentUserId,
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  /// Tab order matching the specification: Chat, Prime, VIP, Biz, AI
  static const List<ChatTab> _tabs = ChatTab.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0, // Prime is first (index 0)
    );
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

  /// Convertir ChatRoom a ChatPreview
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
        lastMessage: chatRoom.lastMessage ?? 'web.chat.new_message'.tr(),
        timeAgo: _formatTime(chatRoom.lastMessageTime),
        isVerified: userData['isVerified'] ?? false,
        isOnline: false,
        unreadCount: chatRoom.getUnreadCount(widget.currentUserId),
        isBlocked: chatRoom.isBlocked(widget.currentUserId, otherUserId),
      );
    } catch (e) {
      debugPrint('❌ Error al convertir ChatRoom: $e');
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}w';
    }
  }

  List<ChatPreview> _filterChats(List<ChatPreview> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      return chat.displayName.toLowerCase().contains(_searchQuery) ||
          chat.username.toLowerCase().contains(_searchQuery) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                if (!tab.isFunctional) return _buildComingSoon();
                return _buildChatStreamByTab(tab);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'profile.sendGifts.comingSoon'.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'web.chat.tab_ai_desc'.tr(),
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Stream de chats filtrado por tab
  Widget _buildChatStreamByTab(ChatTab tab) {
    final stream = _chatService.getChatsStreamByTab(
      widget.currentUserId,
      tab,
    );

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
            'web.chat.error_oops'.tr(),
            icon: Icons.error_outline,
          );
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return _buildEmptyState(
            _getEmptyMessageForTab(tab),
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

            final allPreviews = previewSnapshot.data!
                .where((p) => p != null)
                .cast<ChatPreview>()
                .toList();

            final filteredChats = _filterChats(allPreviews);

            if (filteredChats.isEmpty) {
              return _buildEmptyState('web.chat.no_results'.tr());
            }

            return _buildChatList(filteredChats, tab);
          },
        );
      },
    );
  }

  String _getEmptyMessageForTab(ChatTab tab) {
    switch (tab) {
      case ChatTab.prime:
        return 'web.chat.no_new_messages'.tr();
      case ChatTab.chat:
        return 'web.chat.no_messages'.tr();
      case ChatTab.vip:
        return 'web.chat.no_vip'.tr();
      case ChatTab.biz:
        return 'web.chat.no_biz'.tr();
      case ChatTab.ai:
        return 'profile.sendGifts.comingSoon'.tr();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.username,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
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
          hintText: 'profile.chat.search'.tr(),
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
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                tabs: _tabs
                    .map((tab) =>
                        Tab(child: Center(child: Text(tab.translationKey.tr()))))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatPreview> chats, ChatTab currentTab) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          onTap: () {
            // Mark chat as opened for auto-archive logic
            final chatRoomId = ChatRoom.generateChatRoomId(
              widget.currentUserId,
              chat.userId,
            );
            _chatService.markChatOpened(
              chatRoomId: chatRoomId,
              userId: widget.currentUserId,
            );

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
          },
          // Long-press to move chat to VIP/Biz
          onLongPress: currentTab.isFunctional && currentTab != ChatTab.ai
              ? () => _showMoveToTabDialog(chat, currentTab)
              : null,
        );
      },
    );
  }

  /// Show dialog to move a chat to a different tab
  void _showMoveToTabDialog(ChatPreview chat, ChatTab currentTab) {
    final availableTabs = ChatTab.values
        .where((t) => t.isFunctional && t != currentTab && t != ChatTab.ai)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'web.chat.move_to'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...availableTabs.map((tab) => ListTile(
                    leading: Icon(
                      _getTabIcon(tab),
                      color: _getTabColor(tab),
                    ),
                    title: Text(
                      tab.translationKey.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      final chatRoomId = ChatRoom.generateChatRoomId(
                        widget.currentUserId,
                        chat.userId,
                      );
                      _chatService.moveChatToTab(
                        chatRoomId: chatRoomId,
                        userId: widget.currentUserId,
                        tab: tab,
                      );
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getTabIcon(ChatTab tab) {
    switch (tab) {
      case ChatTab.prime:
        return Icons.inbox_rounded;
      case ChatTab.chat:
        return Icons.chat_bubble_outline;
      case ChatTab.vip:
        return Icons.star_rounded;
      case ChatTab.biz:
        return Icons.business_center_rounded;
      case ChatTab.ai:
        return Icons.smart_toy_outlined;
    }
  }

  Color _getTabColor(ChatTab tab) {
    switch (tab) {
      case ChatTab.prime:
        return const Color(0xFFE91E63);
      case ChatTab.chat:
        return Colors.white70;
      case ChatTab.vip:
        return const Color(0xFFFFD700);
      case ChatTab.biz:
        return const Color(0xFF4CAF50);
      case ChatTab.ai:
        return const Color(0xFF9C27B0);
    }
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
