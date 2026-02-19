import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
import 'package:easy_localization/easy_localization.dart';

/// Web split-pane chat: SideMenu | Chat List | Conversation
class WebChatScreen extends StatefulWidget {
  final String username;
  final String currentUserId;

  const WebChatScreen({
    super.key,
    required this.username,
    required this.currentUserId,
  });

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Selected chat
  String? _selectedChatUserId;
  String? _selectedChatUserName;
  String? _selectedChatUserAvatar;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMenuSmall = size.width < 600;
    final isMenuMedium = size.width >= 600 && size.width < 1200;
    final leftMenuWidth = isMenuSmall
        ? 95.0
        : isMenuMedium
        ? 110.0
        : 140.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(left: leftMenuWidth),
              child: Row(
                children: [
                  // Chat list panel
                  SizedBox(width: 360, child: _buildChatListPanel()),
                  // Divider
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  // Conversation panel
                  Expanded(
                    child: _selectedChatUserId != null
                        ? _buildConversationPanel()
                        : _buildEmptyConversation(),
                  ),
                ],
              ),
            ),
          ),
          // Side Menu
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftMenuWidth,
            child: const SideMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListPanel() {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryPink,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'chat.title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'chat.search'.tr(),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primaryPink,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'web.chat.tab_chat'.tr()),
                Tab(text: 'profile.chat.filter'.tr()),
                Tab(text: 'Prime'),
                Tab(text: 'VIP'),
                Tab(text: 'Biz'),
                Tab(text: 'AI'),
                Tab(text: 'Spam'),
              ],
            ),
          ),
          // Chat list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveChatsList(),
                _buildNewChatsList(),
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

  Widget _buildActiveChatsList() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getActiveChatsStream(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return _buildEmptyChatList();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _ChatRoomTile(
              room: room,
              currentUserId: widget.currentUserId,
              isSelected:
                  _selectedChatUserId != null &&
                  room.participants
                      .where((p) => p != widget.currentUserId)
                      .contains(_selectedChatUserId),
              searchQuery: _searchQuery,
              onTap: (userId, userName, avatar) {
                setState(() {
                  _selectedChatUserId = userId;
                  _selectedChatUserName = userName;
                  _selectedChatUserAvatar = avatar;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNewChatsList() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getNewChatsStream(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return _buildEmptyChatList();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _ChatRoomTile(
              room: room,
              currentUserId: widget.currentUserId,
              isSelected:
                  _selectedChatUserId != null &&
                  room.participants
                      .where((p) => p != widget.currentUserId)
                      .contains(_selectedChatUserId),
              searchQuery: _searchQuery,
              onTap: (userId, userName, avatar) {
                setState(() {
                  _selectedChatUserId = userId;
                  _selectedChatUserName = userName;
                  _selectedChatUserAvatar = avatar;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChatList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'chat.noChats'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationPanel() {
    return UserChatScreen(
      key: ValueKey(_selectedChatUserId),
      otherUserId: _selectedChatUserId!,
      otherUserName: _selectedChatUserName ?? 'User',
      otherUserAvatar: _selectedChatUserAvatar,
      currentUserId: widget.currentUserId,
    );
  }

  Widget _buildEmptyConversation() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              'chat.selectConversation'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'chat.selectConversationDesc'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'profile.sendGifts.comingSoon'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A single chat room tile in the list
class _ChatRoomTile extends StatefulWidget {
  final ChatRoom room;
  final String currentUserId;
  final bool isSelected;
  final String searchQuery;
  final void Function(String userId, String userName, String? avatar) onTap;

  const _ChatRoomTile({
    required this.room,
    required this.currentUserId,
    required this.isSelected,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  State<_ChatRoomTile> createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<_ChatRoomTile> {
  bool _isHovered = false;
  Map<String, dynamic>? _otherUserData;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
  }

  Future<void> _loadOtherUser() async {
    final otherUserId = widget.room.participants.firstWhere(
      (p) => p != widget.currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return;

    try {
      // Try by email first
      final queryByEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: otherUserId)
          .limit(1)
          .get();

      if (queryByEmail.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _otherUserData = queryByEmail.docs.first.data();
            _loaded = true;
          });
        }
        return;
      }

      // Try by document ID
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      if (docSnap.exists && mounted) {
        setState(() {
          _otherUserData = docSnap.data();
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(height: 70);
    }

    final displayName =
        _otherUserData?['displayName'] as String? ??
        _otherUserData?['username'] as String? ??
        'User';
    final username = _otherUserData?['username'] as String? ?? '';
    final avatarUrl = _otherUserData?['avatarUrl'] as String?;

    // Search filter
    if (widget.searchQuery.isNotEmpty) {
      final nameMatch = displayName.toLowerCase().contains(widget.searchQuery);
      final usernameMatch = username.toLowerCase().contains(widget.searchQuery);
      final msgMatch = (widget.room.lastMessage ?? '').toLowerCase().contains(
        widget.searchQuery,
      );
      if (!nameMatch && !usernameMatch && !msgMatch) {
        return const SizedBox.shrink();
      }
    }

    final otherUserId = widget.room.participants.firstWhere(
      (p) => p != widget.currentUserId,
      orElse: () => '',
    );

    final myUnread = widget.room.unreadCount[widget.currentUserId] ?? 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(otherUserId, displayName, avatarUrl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryPink.withValues(alpha: 0.15)
                : _isHovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            border: widget.isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.primaryPink, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: Colors.grey[500], size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.room.lastMessage ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (myUnread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    myUnread > 9 ? '9+' : myUnread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
