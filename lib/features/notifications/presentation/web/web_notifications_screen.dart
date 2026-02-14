import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/services/notifications/notification_model.dart'
    show ChatNotificationModel, NotificationType;
import 'package:migozz_app/core/services/notifications/notification_service.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';

/// Web-optimized notifications screen with SideMenu integration
class WebNotificationsScreen extends StatefulWidget {
  const WebNotificationsScreen({super.key});

  @override
  State<WebNotificationsScreen> createState() => _WebNotificationsScreenState();
}

class _WebNotificationsScreenState extends State<WebNotificationsScreen> {
  List<ChatNotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'unread', 'follow', 'chat'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.instance
          .getNotificationHistory();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [WebNotificationsScreen] Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ChatNotificationModel> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'follow':
        return _notifications
            .where((n) => n.notificationType == NotificationType.follow)
            .toList();
      case 'chat':
        return _notifications
            .where((n) => n.notificationType != NotificationType.follow)
            .toList();
      default:
        return _notifications;
    }
  }

  Future<void> _onNotificationTap(ChatNotificationModel notification) async {
    await NotificationService.instance.markNotificationAsRead(notification.id);
    if (!mounted) return;

    if (notification.notificationType == NotificationType.follow) {
      await _navigateToUserProfile(notification.senderId);
    } else {
      context.push('/chat/${notification.senderId}');
    }
    await _loadNotifications();
  }

  Future<void> _navigateToUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && mounted) {
        final userData = doc.data()!;
        final user = UserDTO.fromMap(userData);
        context.push('/profile-view', extra: user);
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    for (final n in _notifications.where((n) => !n.isRead)) {
      await NotificationService.instance.markNotificationAsRead(n.id);
    }
    await _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'notifications.clearAll.title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'notifications.clearAll.message'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'notifications.clearAll.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'notifications.clearAll.confirm'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService.instance.clearAllNotifications();
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content area
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(left: leftMenuWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      _buildWebHeader(unreadCount),
                      _buildFilterTabs(),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
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

  Widget _buildWebHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 12),
          Icon(Icons.notifications, color: AppColors.primaryPink, size: 28),
          const SizedBox(width: 12),
          Text(
            'notifications.title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text('notifications.markAllRead'.tr()),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              onPressed: _clearAllNotifications,
              tooltip: 'notifications.clearAll.title'.tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _FilterChip(
            label: 'notifications.filter.all'.tr(),
            isSelected: _filter == 'all',
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'notifications.filter.unread'.tr(),
            isSelected: _filter == 'unread',
            onTap: () => setState(() => _filter = 'unread'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'notifications.filter.follows'.tr(),
            isSelected: _filter == 'follow',
            onTap: () => setState(() => _filter = 'follow'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'notifications.filter.messages'.tr(),
            isSelected: _filter == 'chat',
            onTap: () => setState(() => _filter = 'chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    final filtered = _filteredNotifications;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'notifications.empty.title'.tr(),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'notifications.empty.subtitle'.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final notification = filtered[index];
        return _WebNotificationTile(
          notification: notification,
          onTap: () => _onNotificationTap(notification),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPink
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryPink : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _WebNotificationTile extends StatefulWidget {
  final ChatNotificationModel notification;
  final VoidCallback onTap;

  const _WebNotificationTile({required this.notification, required this.onTap});

  @override
  State<_WebNotificationTile> createState() => _WebNotificationTileState();
}

class _WebNotificationTileState extends State<_WebNotificationTile> {
  bool _isHovered = false;

  bool get isFollowNotification =>
      widget.notification.notificationType == NotificationType.follow;

  Color get _accentColor =>
      isFollowNotification ? const Color(0xFF9C27B0) : const Color(0xFFE91E63);

  IconData get _badgeIcon =>
      isFollowNotification ? Icons.person_add : Icons.chat_bubble;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : widget.notification.isRead
                ? const Color(0xFF1C1C1E)
                : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
            border: widget.notification.isRead
                ? null
                : Border.all(color: _accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[800],
                    backgroundImage:
                        widget.notification.senderAvatar != null &&
                            widget.notification.senderAvatar!.isNotEmpty
                        ? NetworkImage(widget.notification.senderAvatar!)
                        : null,
                    child:
                        widget.notification.senderAvatar == null ||
                            widget.notification.senderAvatar!.isEmpty
                        ? Text(
                            (widget.notification.senderName ??
                                        widget.notification.title)
                                    .isNotEmpty
                                ? (widget.notification.senderName ??
                                          widget.notification.title)[0]
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1C1C1E),
                          width: 2,
                        ),
                      ),
                      child: Icon(_badgeIcon, size: 10, color: Colors.white),
                    ),
                  ),
                  if (!widget.notification.isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1C1C1E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: widget.notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notification.body,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Time
              Text(
                widget.notification.timeAgo,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
