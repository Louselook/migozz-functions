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

  final type = message.data['type'] as String?;

  // Skip follow notifications - they are handled by the Firestore listener
  // to avoid duplicate entries in the notifications list
  if (type == 'follow') {
    debugPrint(
      '🔔 [FCM] Skipping follow notification in background handler - handled by Firestore listener',
    );
    return;
  }

  // Show custom notification in background for non-follow types (e.g. chat)
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
  StreamSubscription<QuerySnapshot>? _notificationListener;

  String? _currentUserId;
  Function(String senderId, String chatRoomId)? _onNotificationTap;
  bool _isInitialized = false;

  /// Track processed Firestore notification doc IDs to prevent duplicates.
  /// The Firestore snapshot listener can re-fire 'added' events for the same
  /// document when the query result set changes (e.g. when we update isRead
  /// or when the Cloud Function sets pushSent). This set ensures we never
  /// process the same notification document more than once.
  final Set<String> _processedNotificationIds = {};

  // Notification channel constants
  static const String _chatChannelKey = 'chat_notifications';
  static const String _chatChannelName = 'Chat Notifications';
  static const String _chatChannelDescription =
      'Notifications for new chat messages';

  static const String _followChannelKey = 'follow_notifications';
  static const String _followChannelName = 'Follow Notifications';
  static const String _followChannelDescription =
      'Notifications when someone follows you';

  /// Initialize the notification service
  Future<void> initialize({
    required String userId,
    Function(String senderId, String chatRoomId)? onNotificationTap,
  }) async {
    // Prevent duplicate initialization for the same user
    if (_isInitialized && _currentUserId == userId) {
      debugPrint(
        '⚠️ [NotificationService] Already initialized for user: $userId, skipping',
      );
      return;
    }

    // If switching users, clean up first
    if (_isInitialized && _currentUserId != userId) {
      debugPrint(
        '🔔 [NotificationService] Switching from $_currentUserId to $userId, cleaning up first',
      );
      dispose();
    }

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

    // Set up Firestore notification listener for follow notifications
    await _setupFirestoreNotificationListener();

    // Check for initial message (app opened from terminated state via notification)
    await _checkInitialMessage();

    _isInitialized = true;

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

      debugPrint(
        '🔔 [NotificationService] FCM permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          '⚠️ [NotificationService] Notification permission denied by user',
        );
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        debugPrint('✅ [NotificationService] Notification permission granted');
      }

      // Request awesome_notifications permissions
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        debugPrint(
          '🔔 [NotificationService] Requesting awesome_notifications permission',
        );
        await AwesomeNotifications().requestPermissionToSendNotifications();
      } else {
        debugPrint(
          '✅ [NotificationService] awesome_notifications already allowed',
        );
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
        debugPrint(
          '🔔 [NotificationService] FCM Token result: ${token != null ? "received" : "null"}',
        );
      }

      if (token != null) {
        debugPrint(
          '🔔 [NotificationService] FCM Token: ${token.substring(0, 20)}...',
        );
        debugPrint(
          '🔔 [NotificationService] Full token length: ${token.length}',
        );
        await _saveFCMToken(token);
      } else {
        debugPrint(
          '⚠️ [NotificationService] FCM Token is null - push notifications will not work',
        );
        debugPrint(
          '⚠️ [NotificationService] This may happen on iOS simulator or if APNs is not configured',
        );
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
      debugPrint(
        '⚠️ [NotificationService] Cannot save FCM token - currentUserId is null',
      );
      return;
    }

    debugPrint(
      '🔔 [NotificationService] Saving FCM token for user: $_currentUserId',
    );

    try {
      // _currentUserId is an email, so we need to query by email to find the user document
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      debugPrint(
        '🔔 [NotificationService] Query returned ${querySnapshot.docs.length} documents',
      );

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '❌ [NotificationService] User not found for email: $_currentUserId',
        );
        return;
      }

      final userDoc = querySnapshot.docs.first;
      debugPrint('🔔 [NotificationService] Found user document: ${userDoc.id}');

      await userDoc.reference.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '✅ [NotificationService] FCM token saved to Firestore for user ${userDoc.id}',
      );
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
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
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

  /// Set up Firestore notification listener
  /// Listens for new notification documents in users/{userId}/notifications
  Future<void> _setupFirestoreNotificationListener() async {
    try {
      // Cancel existing listener and clear processed IDs
      _notificationListener?.cancel();
      _processedNotificationIds.clear();

      // Get user document ID from email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '❌ [NotificationService] User not found for Firestore listener',
        );
        return;
      }

      final userDocId = querySnapshot.docs.first.id;

      debugPrint(
        '🔔 [NotificationService] Setting up Firestore listener for user: $userDocId',
      );

      // First, mark all existing unread follow notifications as read so the
      // listener's initial snapshot doesn't re-process old notifications.
      // This prevents the "5 notifications on app start" problem.
      final existingUnread = await _firestore
          .collection('users')
          .doc(userDocId)
          .collection('notifications')
          .where('type', isEqualTo: 'follow')
          .where('isRead', isEqualTo: false)
          .get();

      if (existingUnread.docs.isNotEmpty) {
        debugPrint(
          '🔔 [NotificationService] Marking ${existingUnread.docs.length} existing unread follow notifications as read',
        );
        final batch = _firestore.batch();
        for (final doc in existingUnread.docs) {
          batch.update(doc.reference, {'isRead': true});
          // Also add to processed set in case the listener fires before batch completes
          _processedNotificationIds.add(doc.id);
        }
        await batch.commit();
      }

      // Listen only for unread follow notifications.
      // Since we just marked all existing ones as read above, only truly NEW
      // notifications (created after this point) will appear in the results.
      _notificationListener = _firestore
          .collection('users')
          .doc(userDocId)
          .collection('notifications')
          .where('type', isEqualTo: 'follow')
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots()
          .listen(
            (snapshot) {
              debugPrint(
                '🔔 [NotificationService] Firestore notification snapshot: ${snapshot.docs.length} docs, ${snapshot.docChanges.length} changes',
              );

              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final docId = change.doc.id;

                  // Skip if we already processed this document
                  if (_processedNotificationIds.contains(docId)) {
                    debugPrint(
                      '🔕 [NotificationService] Skipping already-processed notification: $docId',
                    );
                    continue;
                  }

                  // Mark as processed immediately to prevent any race conditions
                  _processedNotificationIds.add(docId);

                  debugPrint(
                    '🔔 [NotificationService] New unread notification document detected: $docId',
                  );
                  _handleFirestoreNotification(change.doc);
                }
              }
            },
            onError: (error) {
              debugPrint(
                '❌ [NotificationService] Error in Firestore listener: $error',
              );
            },
          );

      debugPrint(
        '✅ [NotificationService] Firestore notification listener set up',
      );
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error setting up Firestore listener: $e',
      );
    }
  }

  /// Handle a notification document from Firestore.
  /// This is the SINGLE source of truth for displaying follow notifications.
  /// The Cloud Function sends a data-only FCM message (no notification payload),
  /// so we are responsible for showing the notification banner.
  Future<void> _handleFirestoreNotification(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final fromUserId = data['fromUserId'] as String?;

      debugPrint(
        '🔔 [NotificationService] Handling Firestore notification: docId=${doc.id}, from=$fromUserId',
      );

      if (fromUserId == null || fromUserId.isEmpty) {
        // Mark as read so it doesn't keep appearing
        await doc.reference.update({'isRead': true});
        return;
      }

      // Get follower info
      final followerDoc = await _firestore
          .collection('users')
          .doc(fromUserId)
          .get();
      if (!followerDoc.exists) {
        debugPrint(
          '⚠️ [NotificationService] Follower user not found: $fromUserId',
        );
        await doc.reference.update({'isRead': true});
        return;
      }

      final followerData = followerDoc.data()!;
      final followerName =
          followerData['displayName']?.toString() ??
          followerData['username']?.toString() ??
          'Someone';
      final followerAvatar = followerData['avatarUrl']?.toString();

      debugPrint(
        '🔔 [NotificationService] Follower info: name=$followerName',
      );

      // Mark as read in Firestore FIRST to ensure the query drops this doc
      // from the snapshot results, preventing any re-processing.
      await doc.reference.update({'isRead': true});

      // Show the notification banner AND save to history
      debugPrint(
        '🔔 [NotificationService] Showing follow notification for $followerName',
      );
      await showFollowNotification(
        followerId: fromUserId,
        followerName: followerName,
        followerAvatar: followerAvatar,
      );

      debugPrint(
        '✅ [NotificationService] Follow notification processed for $followerName',
      );
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error handling Firestore notification: $e',
      );
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final senderId = data['senderId'] as String?;
    final chatRoomId = data['chatRoomId'] as String?;

    // Skip follow notifications - they are handled by the Firestore listener
    // to avoid duplicate entries in the notifications list
    if (type == 'follow') {
      debugPrint(
        '🔕 [NotificationService] Skipping follow FCM in foreground - handled by Firestore listener',
      );
      return;
    }

    // Check if we should show the notification
    if (senderId != null &&
        !_activeChatManager.shouldShowNotification(
          senderId: senderId,
          chatRoomId: chatRoomId,
        )) {
      debugPrint(
        '🔕 [NotificationService] Notification suppressed - user in active chat',
      );
      return;
    }

    // Show custom notification in foreground for non-follow types (e.g. chat)
    // Firebase doesn't auto-display in foreground on Android, so we must show it
    debugPrint('🔔 [NotificationService] Showing foreground notification');
    showNotificationFromFCM(message, isForeground: true);
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
  ///
  /// [isForeground] - true if app is in foreground, false if in background.
  /// Since Cloud Functions now send data-only messages (no notification payload),
  /// we ALWAYS show custom notification for both foreground and background.
  Future<void> showNotificationFromFCM(
    RemoteMessage message, {
    bool isForeground = false,
  }) async {
    final data = message.data;
    final type = data['type'] as String?;

    debugPrint(
      '🔔 [FCM] showNotificationFromFCM called: type=$type, isForeground=$isForeground',
    );

    // Skip follow notifications - they are handled by the Firestore listener
    // to avoid duplicate entries in the notifications list
    if (type == 'follow') {
      debugPrint(
        '🔕 [NotificationService] Skipping follow FCM in showNotificationFromFCM - handled by Firestore listener',
      );
      return;
    }

    // Extract notification data from the data payload
    final title = data['title'] ?? 'New Message';
    final body = data['body'] ?? 'You have a new message';
    final senderId = data['senderId'] as String?;
    final chatRoomId = data['chatRoomId'] as String?;
    final senderName = data['senderName'] as String?;
    final senderAvatar = data['senderAvatar'] as String?;

    debugPrint(
      '🔔 [NotificationService] Showing notification: title=$title, senderId=$senderId',
    );

    // Always show custom notification since Cloud Functions send data-only messages
    // This works for both foreground and background
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

    debugPrint(
      '🔔 [NotificationService] Follow notification shown for $followerName',
    );
  }

  /// Save notification to local history with grouping/deduplication.
  ///
  /// Grouping rules:
  /// - For the same person and same notification type: Only keep the most recent.
  ///   Example: If User A sends multiple chat messages, only show the latest.
  /// - For the same person but different notification types: Keep one per type.
  ///   Example: If User A follows you AND sends a chat, show both notifications.
  /// - When a new notification arrives from the same person with the same type,
  ///   it replaces the old one (not creating a duplicate entry).
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
      final notificationsJson =
          prefs.getStringList('notifications_history') ?? [];

      // First, check for exact duplicates within 2 seconds to prevent
      // race condition duplicates (same sender, type, title, and body).
      final now = DateTime.now();
      for (final existingJson in notificationsJson) {
        try {
          final existing = ChatNotificationModel.fromJson(
            jsonDecode(existingJson) as Map<String, dynamic>,
          );
          if (existing.senderId == senderId &&
              existing.notificationType == notificationType &&
              existing.title == title &&
              existing.body == body &&
              now.difference(existing.timestamp).inSeconds.abs() < 2) {
            debugPrint(
              '🔕 [NotificationService] Exact duplicate notification skipped: '
              'senderId=$senderId, type=$notificationType, body=$body',
            );
            return;
          }
        } catch (_) {
          // Skip malformed entries during dedup check
        }
      }

      // Remove any existing notification from the same sender with the same type.
      // This implements the grouping logic: only keep the most recent notification
      // per sender per type.
      String? removedNotificationId;
      notificationsJson.removeWhere((existingJson) {
        try {
          final existing = ChatNotificationModel.fromJson(
            jsonDecode(existingJson) as Map<String, dynamic>,
          );
          if (existing.senderId == senderId &&
              existing.notificationType == notificationType) {
            removedNotificationId = existing.id;
            debugPrint(
              '🔄 [NotificationService] Replacing old notification from same sender/type: '
              'senderId=$senderId, type=$notificationType, oldId=${existing.id}',
            );
            return true; // Remove this notification
          }
          return false; // Keep this notification
        } catch (_) {
          // Skip malformed entries
          return false;
        }
      });

      // Create the new notification
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

      // Insert at the beginning (most recent first)
      notificationsJson.insert(0, jsonEncode(notification.toJson()));

      // Keep only last 100 notifications
      if (notificationsJson.length > 100) {
        notificationsJson.removeRange(100, notificationsJson.length);
      }

      await prefs.setStringList('notifications_history', notificationsJson);

      if (removedNotificationId != null) {
        debugPrint(
          '✅ [NotificationService] Notification replaced in history: '
          'senderId=$senderId, type=$notificationType, newId=${notification.id}, '
          'replacedId=$removedNotificationId',
        );
      } else {
        debugPrint(
          '✅ [NotificationService] New notification saved to history: '
          'senderId=$senderId, type=$notificationType, id=${notification.id}',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error saving notification to history: $e',
      );
    }
  }

  /// Get notification history
  Future<List<ChatNotificationModel>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList('notifications_history') ?? [];

      return notificationsJson
          .map((json) => ChatNotificationModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error getting notification history: $e',
      );
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList('notifications_history') ?? [];

      final updatedNotifications = notificationsJson.map((json) {
        final notification = ChatNotificationModel.fromJson(jsonDecode(json));
        if (notification.id == notificationId) {
          return jsonEncode(notification.copyWith(isRead: true).toJson());
        }
        return json;
      }).toList();

      await prefs.setStringList('notifications_history', updatedNotifications);
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error marking notification as read: $e',
      );
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
    debugPrint('🔔 [NotificationService] Disposing service');
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _notificationListener?.cancel();
    _processedNotificationIds.clear();
    _isInitialized = false;
    _currentUserId = null;
    _onNotificationTap = null;
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
        debugPrint(
          '🔔 [Notification] Stored pending navigation: senderId=$senderId, chatRoomId=$chatRoomId',
        );
      }
    } catch (e) {
      debugPrint('❌ [Notification] Error parsing payload: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _onNotificationCreatedMethod(
  ReceivedNotification receivedNotification,
) async {
  debugPrint('🔔 [Notification] Created: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> _onNotificationDisplayedMethod(
  ReceivedNotification receivedNotification,
) async {
  debugPrint('🔔 [Notification] Displayed: ${receivedNotification.id}');
}

@pragma('vm:entry-point')
Future<void> _onDismissActionReceivedMethod(
  ReceivedAction receivedAction,
) async {
  debugPrint('🔔 [Notification] Dismissed: ${receivedAction.id}');
}
