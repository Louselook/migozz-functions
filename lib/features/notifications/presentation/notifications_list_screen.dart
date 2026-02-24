import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/services/notifications/notification_model.dart'
    show ChatNotificationModel, NotificationType;
import 'package:migozz_app/core/services/notifications/notification_service.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

/// Screen to display list of notifications
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  List<ChatNotificationModel> _notifications = [];
  bool _isLoading = true;

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
      debugPrint('❌ [NotificationsListScreen] Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onNotificationTap(ChatNotificationModel notification) async {
    // Mark as read
    await NotificationService.instance.markNotificationAsRead(notification.id);

    if (mounted) {
      // Navigate based on notification type
      if (notification.notificationType == NotificationType.follow) {
        // Navigate to the follower's profile by loading user data first
        await _navigateToUserProfile(notification.senderId);
      } else {
        // Navigate to chats list first, then to the specific chat
        context.push('/chats');

        // Then navigate to the specific chat after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.push('/chat/${notification.senderId}');
          }
        });
      }
    }

    // Reload to update UI
    await _loadNotifications();
  }

  /// Navigate to a user's profile by their user ID
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
      } else {
        debugPrint('❌ [NotificationsListScreen] User not found: $userId');
      }
    } catch (e) {
      debugPrint('❌ [NotificationsListScreen] Error loading user profile: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'notifications.clearAll.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'notifications.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              onPressed: _clearAllNotifications,
              tooltip: 'notifications.clearAll.title'.tr(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_notifications.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ChatNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  bool get isFollowNotification =>
      notification.notificationType == NotificationType.follow;

  Color get _accentColor => isFollowNotification
      ? const Color(0xFF9C27B0) // Purple for follow
      : const Color(0xFFE91E63); // Pink for chat

  IconData get _badgeIcon =>
      isFollowNotification ? Icons.person_add : Icons.chat_bubble;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF1C1C1E)
            : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: _accentColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage:
                  notification.senderAvatar != null &&
                      notification.senderAvatar!.isNotEmpty
                  ? NetworkImage(notification.senderAvatar!)
                  : null,
              onBackgroundImageError:
                  notification.senderAvatar != null &&
                      notification.senderAvatar!.isNotEmpty
                  ? (_, __) {}
                  : null,
              child:
                  notification.senderAvatar == null ||
                      notification.senderAvatar!.isEmpty
                  ? Text(
                      (notification.senderName ?? notification.title).isNotEmpty
                          ? (notification.senderName ?? notification.title)[0]
                                .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Notification type badge
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1C1C1E), width: 2),
                ),
                child: Icon(_badgeIcon, size: 10, color: Colors.white),
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
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
        title: Text(
          notification.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      ),
    );
  }
}
