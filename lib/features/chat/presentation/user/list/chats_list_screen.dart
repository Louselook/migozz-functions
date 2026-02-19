import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
              children: [
                _buildChatStream(isActive: true),
                _buildChatStream(isActive: false),
                _buildComingSoon(),
                _buildComingSoon(),
                _buildComingSoon(),
                _buildComingSoon(),
                _buildComingSoon(),
              ],
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
          Icon(Icons.construction, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'profile.sendGifts.comingSoon'.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Stream de chats
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
          // Mostrar error de forma amigable
          return _buildEmptyState(
            'web.chat.error_oops'.tr(),
            icon: Icons.error_outline,
          );
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return _buildEmptyState(
            isActive
                ? 'web.chat.no_messages'.tr()
                : 'web.chat.no_new_messages'.tr(),
          );
        }

        // 🆕 Crear una key única basada en los unreadCount para forzar rebuild
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

            return _buildChatList(filteredChats);
          },
        );
      },
    );
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
                tabs: [
                  Tab(child: Center(child: Text('web.chat.tab_chat'.tr()))),
                  Tab(child: Center(child: Text('profile.chat.filter'.tr()))),
                  Tab(child: Center(child: Text('Prime'))),
                  Tab(child: Center(child: Text('VIP'))),
                  Tab(child: Center(child: Text('Biz'))),
                  Tab(child: Center(child: Text('AI'))),
                  Tab(child: Center(child: Text('Spam'))),
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
            // Navegar al chat pasando solo datos básicos
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
              // 🆕 Forzar rebuild al regresar para actualizar unreadCount
              if (mounted) setState(() {});
            });
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
