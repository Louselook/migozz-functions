import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/services/notifications/active_chat_manager.dart';
import 'package:migozz_app/core/services/notifications/notification_model.dart'
    show ChatNotificationModel, NotificationType;
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background message received: ${message.messageId}');

  // Always show custom notification in background
  // This ensures consistent notification display across all scenarios
  debugPrint('🔔 [FCM] Showing background notification');
  await NotificationService.instance.showNotificationFromFCM(message);
}

/// Main notification service for handling FCM and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActiveChatManager _activeChatManager = ActiveChatManager.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  String? _currentUserId;
  Function(String senderId, String chatRoomId)? _onNotificationTap;

  // Notification channel constants
  static const String _chatChannelKey = 'chat_notifications';
  static const String _chatChannelName = 'Chat Notifications';
  static const String _chatChannelDescription = 'Notifications for new chat messages';

  static const String _followChannelKey = 'follow_notifications';
  static const String _followChannelName = 'Follow Notifications';
  static const String _followChannelDescription = 'Notifications when someone follows you';

  /// Initialize the notification service
  Future<void> initialize({
    required String userId,
    Function(String senderId, String chatRoomId)? onNotificationTap,
  }) async {
    _currentUserId = userId;
    _onNotificationTap = onNotificationTap;

    debugPrint('🔔 [NotificationService] Initializing for user: $userId');

    // Initialize awesome_notifications
    await _initializeAwesomeNotifications();

    // Request permissions
    await _requestPermissions();

    // Get and save FCM token
    await _setupFCMToken();

    // Set up message handlers
    _setupMessageHandlers();

    // Check for initial message (app opened from terminated state via notification)
    await _checkInitialMessage();

    debugPrint('✅ [NotificationService] Initialization complete');
  }

  /// Initialize awesome_notifications
  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: _chatChannelKey,
          channelName: _chatChannelName,
          channelDescription: _chatChannelDescription,
          defaultColor: const Color(0xFFE91E63),
          ledColor: const Color(0xFFE91E63),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: _followChannelKey,
          channelName: _followChannelName,
          channelDescription: _followChannelDescription,
          defaultColor: const Color(0xFF9C27B0),
          ledColor: const Color(0xFF9C27B0),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: kDebugMode,
    );

    // Set up notification action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request FCM permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [NotificationService] FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ [NotificationService] Notification permission denied by user');
      } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [NotificationService] Notification permission granted');
      }

      // Request awesome_notifications permissions
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        debugPrint('🔔 [NotificationService] Requesting awesome_notifications permission');
        await AwesomeNotifications().requestPermissionToSendNotifications();
      } else {
        debugPrint('✅ [NotificationService] awesome_notifications already allowed');
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Error requesting permissions: $e');
    }
  }

  /// Set up FCM token and save to Firestore
  Future<void> _setupFCMToken() async {
    try {
      // Get the token
      String? token;
      if (kIsWeb) {
        // For web, you need to provide a VAPID key
        // token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY');
        debugPrint('🔔 [NotificationService] Web FCM not fully configured');
        return;
      } else {
        debugPrint('🔔 [NotificationService] Getting FCM token...');
        token = await _messaging.getToken();
        debugPrint('🔔 [NotificationService] FCM Token result: ${token != null ? "received" : "null"}');
      }

      if (token != null) {
        debugPrint('🔔 [NotificationService] FCM Token: ${token.substring(0, 20)}...');
        debugPrint('🔔 [NotificationService] Full token length: ${token.length}');
        await _saveFCMToken(token);
      } else {
        debugPrint('⚠️ [NotificationService] FCM Token is null - push notifications will not work');
        debugPrint('⚠️ [NotificationService] This may happen on iOS simulator or if APNs is not configured');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 [NotificationService] FCM Token refreshed');
        _saveFCMToken(newToken);
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationService] Error getting FCM token: $e');
      debugPrint('❌ [NotificationService] Stack trace: $stackTrace');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ [NotificationService] Cannot save FCM token - currentUserId is null');
      return;
    }

    debugPrint('🔔 [NotificationService] Saving FCM token for user: $_currentUserId');

    try {
      // _currentUserId is an email, so we need to query by email to find the user document
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      debugPrint('🔔 [NotificationService] Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ [NotificationService] User not found for email: $_currentUserId');
        return;
      }

      final userDoc = querySnapshot.docs.first;
      debugPrint('🔔 [NotificationService] Found user document: ${userDoc.id}');

      await userDoc.reference.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [NotificationService] FCM token saved to Firestore for user ${userDoc.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationService] Error saving FCM token: $e');
      debugPrint('❌ [NotificationService] Stack trace: $stackTrace');
    }
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Cancel existing subscriptions to prevent duplicates
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();

    // Handle foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('🔔 [FCM] Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle when app is opened from background via notification
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 [FCM] App opened from notification: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  /// Check for initial message when app is opened from terminated state
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 [FCM] App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final senderId = data['senderId'] as String?;
    final chatRoomId = data['chatRoomId'] as String?;

    // Check if we should show the notification
    if (senderId != null && !_activeChatManager.shouldShowNotification(
      senderId: senderId,
      chatRoomId: chatRoomId,
    )) {
      debugPrint('🔕 [NotificationService] Notification suppressed - user in active chat');
      return;
    }

    // Always show custom notification in foreground
    // Firebase doesn't auto-display in foreground on Android
    debugPrint('🔔 [NotificationService] Showing foreground notification');
    showNotificationFromFCM(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final senderId = data['senderId'] as String?;
    final chatRoomId = data['chatRoomId'] as String?;

    if (senderId != null && chatRoomId != null && _onNotificationTap != null) {
      _onNotificationTap!(senderId, chatRoomId);
    }
  }

  /// Show notification from FCM message
  Future<void> showNotificationFromFCM(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'New Message';
    final body = notification?.body ?? data['body'] ?? 'You have a new message';
    final senderId = data['senderId'] as String?;
    final chatRoomId = data['chatRoomId'] as String?;
    final senderName = data['senderName'] as String?;
    final senderAvatar = data['senderAvatar'] as String?;

    await showChatNotification(
      title: title,
      body: body,
      senderId: senderId ?? '',
      chatRoomId: chatRoomId ?? '',
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  /// Show a chat notification
  Future<void> showChatNotification({
    required String title,
    required String body,
    required String senderId,
    required String chatRoomId,
    String? senderName,
    String? senderAvatar,
  }) async {
    // Check if we should show the notification
    if (!_activeChatManager.shouldShowNotification(
      senderId: senderId,
      chatRoomId: chatRoomId,
    )) {
      return;
    }

    final payload = jsonEncode({
      'senderId': senderId,
      'chatRoomId': chatRoomId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    });

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _chatChannelKey,
        title: title,
        body: body,
        payload: {'data': payload},
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        autoDismissible: true,
      ),
    );

    // Save notification to local storage for the notifications list
    await _saveNotificationToHistory(
      title: title,
      body: body,
      senderId: senderId,
      chatRoomId: chatRoomId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      notificationType: NotificationType.chat,
    );
  }

  /// Show a follow notification
  Future<void> showFollowNotification({
    required String followerId,
    required String followerName,
    String? followerAvatar,
  }) async {
    final title = followerName;
    final body = 'Started following you';

    final payload = jsonEncode({
      'followerId': followerId,
      'followerName': followerName,
      'followerAvatar': followerAvatar,
      'notificationType': 'follow',
    });

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _followChannelKey,
        title: title,
        body: body,
        payload: {'data': payload},
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Social,
        wakeUpScreen: true,
        autoDismissible: true,
      ),
    );

    // Save notification to local storage for the notifications list
    await _saveNotificationToHistory(
      title: title,
      body: body,
      senderId: followerId,
      senderName: followerName,
      senderAvatar: followerAvatar,
      notificationType: NotificationType.follow,
    );

    debugPrint('🔔 [NotificationService] Follow notification shown for $followerName');
  }

  /// Save notification to local history
  Future<void> _saveNotificationToHistory({
    required String title,
    required String body,
    required String senderId,
    String chatRoomId = '',
    String? senderName,
    String? senderAvatar,
    NotificationType notificationType = NotificationType.chat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications_history') ?? [];

      final notification = ChatNotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        senderId: senderId,
        chatRoomId: chatRoomId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        timestamp: DateTime.now(),
        isRead: false,
        notificationType: notificationType,
      );

      notificationsJson.insert(0, jsonEncode(notification.toJson()));

      // Keep only last 100 notifications
      if (notificationsJson.length > 100) {
        notificationsJson.removeRange(100, notificationsJson.length);
      }

      await prefs.setStringList('notifications_history', notificationsJson);
    } catch (e) {
      debugPrint('❌ [NotificationService] Error saving notification to history: $e');
    }
  }

  /// Get notification history
  Future<List<ChatNotificationModel>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications_history') ?? [];

      return notificationsJson
          .map((json) => ChatNotificationModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ [NotificationService] Error getting notification history: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications_history') ?? [];

      final updatedNotifications = notificationsJson.map((json) {
        final notification = ChatNotificationModel.fromJson(jsonDecode(json));
        if (notification.id == notificationId) {
          return jsonEncode(notification.copyWith(isRead: true).toJson());
        }
        return json;
      }).toList();

      await prefs.setStringList('notifications_history', updatedNotifications);
    } catch (e) {
      debugPrint('❌ [NotificationService] Error marking notification as read: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notifications_history');
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      debugPrint('❌ [NotificationService] Error clearing notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final notifications = await getNotificationHistory();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Dispose the service
  void dispose() {
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
  }

  /// Remove FCM token when user logs out
  Future<void> removeToken() async {
    if (_currentUserId == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // _currentUserId is an email, so we need to query by email to find the user document
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: _currentUserId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
        }
      }
      await _messaging.deleteToken();
      debugPrint('✅ [NotificationService] FCM token removed');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error removing FCM token: $e');
    }
  }
}

// Static callback methods for awesome_notifications
@pragma('vm:entry-point')
Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
  debugPrint('🔔 [Notification] Action received: ${receivedAction.payload}');

  final payloadData = receivedAction.payload?['data'];
  if (payloadData != null) {
    try {
      final data = jsonDecode(payloadData);
      final senderId = data['senderId'] as String?;
      final chatRoomId = data['chatRoomId'] as String?;

      if (senderId != null && chatRoomId != null) {
        // Store the navigation data for when the app is ready
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_notification_navigation', payloadData);
        debugPrint('🔔 [Notification] Stored pending navigation: senderId=$senderId, chatRoomId=$chatRoomId');
      }
    } catch (e) {
      debugPrint('❌ [Notification] Error parsing payload: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
  debugPrint('🔔 [Notification] Created: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  debugPrint('🔔 [Notification] Displayed: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
  debugPrint('🔔 [Notification] Dismissed: ${receivedAction.id}');
}

