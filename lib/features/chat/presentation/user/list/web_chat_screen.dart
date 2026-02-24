import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/chat/data/datasources/chat_service.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_tab.dart';
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

  static const List<ChatTab> _tabs = ChatTab.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        ? 60.0
        : isMenuMedium
        ? 70.0
        : 80.0;

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
              tabs: _tabs
                  .map((tab) => Tab(text: tab.translationKey.tr()))
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                if (!tab.isFunctional) return _buildComingSoon();
                return _buildChatsListByTab(tab);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsListByTab(ChatTab tab) {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getChatsStreamByTab(widget.currentUserId, tab),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return _buildEmptyChatList(tab);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _ChatRoomTile(
              room: room,
              currentUserId: widget.currentUserId,
              currentTab: tab,
              isSelected:
                  _selectedChatUserId != null &&
                  room.participants
                      .where((p) => p != widget.currentUserId)
                      .contains(_selectedChatUserId),
              searchQuery: _searchQuery,
              onTap: (userId, userName, avatar) {
                // Mark chat as opened for auto-archive
                _chatService.markChatOpened(
                  chatRoomId: room.chatRoomId,
                  userId: widget.currentUserId,
                );
                setState(() {
                  _selectedChatUserId = userId;
                  _selectedChatUserName = userName;
                  _selectedChatUserAvatar = avatar;
                });
              },
              onMoveToTab: (newTab) {
                _chatService.moveChatToTab(
                  chatRoomId: room.chatRoomId,
                  userId: widget.currentUserId,
                  tab: newTab,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChatList(ChatTab tab) {
    String message;
    switch (tab) {
      case ChatTab.prime:
        message = 'web.chat.no_new_messages'.tr();
      case ChatTab.chat:
        message = 'chat.noChats'.tr();
      case ChatTab.vip:
        message = 'web.chat.no_vip'.tr();
      case ChatTab.biz:
        message = 'web.chat.no_biz'.tr();
      case ChatTab.ai:
        message = 'profile.sendGifts.comingSoon'.tr();
    }
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
            message,
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
            Icons.smart_toy_outlined,
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
          const SizedBox(height: 8),
          Text(
            'web.chat.tab_ai_desc'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
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
  final ChatTab currentTab;
  final bool isSelected;
  final String searchQuery;
  final void Function(String userId, String userName, String? avatar) onTap;
  final void Function(ChatTab newTab)? onMoveToTab;

  const _ChatRoomTile({
    required this.room,
    required this.currentUserId,
    required this.currentTab,
    required this.isSelected,
    required this.searchQuery,
    required this.onTap,
    this.onMoveToTab,
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
        onSecondaryTapUp: widget.onMoveToTab != null
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
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

  void _showContextMenu(BuildContext context, Offset position) {
    final availableTabs = ChatTab.values
        .where((t) =>
            t.isFunctional && t != widget.currentTab && t != ChatTab.ai)
        .toList();

    showMenu<ChatTab>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: const Color(0xFF2C2C2E),
      items: [
        PopupMenuItem<ChatTab>(
          enabled: false,
          child: Text(
            'web.chat.move_to'.tr(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...availableTabs.map((tab) => PopupMenuItem<ChatTab>(
              value: tab,
              child: Row(
                children: [
                  Icon(_getTabIcon(tab), color: _getTabColor(tab), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    tab.translationKey.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )),
      ],
    ).then((selectedTab) {
      if (selectedTab != null && widget.onMoveToTab != null) {
        widget.onMoveToTab!(selectedTab);
      }
    });
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
}
