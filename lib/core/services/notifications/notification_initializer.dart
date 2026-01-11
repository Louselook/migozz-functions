import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/services/notifications/notification_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global router reference for notification navigation
GoRouter? _globalRouter;

/// Widget that initializes notifications when user is authenticated
class NotificationInitializer extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const NotificationInitializer({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<NotificationInitializer> createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  bool _isInitialized = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    debugPrint('🔔🔔🔔 [NotificationInitializer] initState called - Widget created!');
    // Set the global router reference
    _globalRouter = widget.router;
    debugPrint('✅ [NotificationInitializer] Global router set');
    // Set up background message handler - MUST be called early
    _setupBackgroundHandler();
    // Listen for app lifecycle changes to check for pending navigation
    _setupAppLifecycleListener();
  }

  void _setupBackgroundHandler() {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ [NotificationInitializer] Background message handler registered');
    } catch (e) {
      debugPrint('❌ [NotificationInitializer] Error registering background handler: $e');
    }
  }

  void _setupAppLifecycleListener() {
    // Listen for app lifecycle changes to check for pending navigation when app comes to foreground
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(
      onResumed: _checkPendingNavigation,
    ));
    debugPrint('✅ [NotificationInitializer] App lifecycle listener registered');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndInitialize();
  }

  Future<void> _checkAndInitialize() async {
    final authState = context.read<AuthCubit>().state;

    debugPrint('🔔 [NotificationInitializer] Checking auth state: ${authState.status}');
    debugPrint('🔔 [NotificationInitializer] User profile: ${authState.userProfile?.email ?? "null"}');
    debugPrint('🔔 [NotificationInitializer] Is initialized: $_isInitialized, Last user: $_lastUserId');

    if (authState.status == AuthStatus.authenticated &&
        authState.userProfile != null) {
      final userId = authState.userProfile!.email;

      // Only initialize if not already initialized or user changed
      if (!_isInitialized || _lastUserId != userId) {
        debugPrint('🔔 [NotificationInitializer] Will initialize for user: $userId');
        await _initializeNotifications(userId);
      } else {
        debugPrint('🔔 [NotificationInitializer] Already initialized for this user, skipping');
      }
    } else if (authState.status == AuthStatus.notAuthenticated && _isInitialized) {
      // User logged out, clean up
      await _cleanupNotifications();
    } else {
      debugPrint('🔔 [NotificationInitializer] Not authenticated or no profile, skipping initialization');
    }
  }

  Future<void> _initializeNotifications(String userId) async {
    if (kIsWeb) {
      debugPrint('🔔 [NotificationInitializer] Skipping notification init on web');
      return;
    }

    debugPrint('🔔 [NotificationInitializer] Initializing notifications for user: $userId');

    try {
      await NotificationService.instance.initialize(
        userId: userId,
        onNotificationTap: _handleNotificationTap,
      );

      _isInitialized = true;
      _lastUserId = userId;

      // Check for pending navigation from notification tap
      await _checkPendingNavigation();

      debugPrint('✅ [NotificationInitializer] Notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ [NotificationInitializer] Error initializing notifications: $e');
    }
  }

  Future<void> _cleanupNotifications() async {
    debugPrint('🔔 [NotificationInitializer] Cleaning up notifications');
    
    try {
      await NotificationService.instance.removeToken();
      NotificationService.instance.dispose();
      _isInitialized = false;
      _lastUserId = null;
    } catch (e) {
      debugPrint('❌ [NotificationInitializer] Error cleaning up notifications: $e');
    }
  }

  void _handleNotificationTap(String senderId, String chatRoomId) {
    debugPrint('🔔 [NotificationInitializer] Notification tapped - sender: $senderId, room: $chatRoomId');

    // Use the global router reference
    if (_globalRouter != null) {
      try {
        debugPrint('🔔 [NotificationInitializer] Using global router to navigate');

        // First navigate to chats list
        _globalRouter!.push('/chats');

        // Then navigate to the specific chat after a short delay to ensure the chats screen is loaded
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            _globalRouter!.push('/chat/$senderId');
            debugPrint('✅ [NotificationInitializer] Successfully navigated to chat: $senderId');
          } catch (e) {
            debugPrint('❌ [NotificationInitializer] Error navigating to chat: $e');
          }
        });
      } catch (e) {
        debugPrint('❌ [NotificationInitializer] Error navigating to chats: $e');
        debugPrint('⚠️ [NotificationInitializer] Storing navigation data for later');
        _storeNavigationData(senderId, chatRoomId);
      }
    } else {
      debugPrint('⚠️ [NotificationInitializer] Global router not available, storing navigation data');
      _storeNavigationData(senderId, chatRoomId);
    }
  }

  Future<void> _storeNavigationData(String senderId, String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_navigation', jsonEncode({
        'senderId': senderId,
        'chatRoomId': chatRoomId,
      }));
      debugPrint('🔔 [NotificationInitializer] Navigation data stored for later');
    } catch (e) {
      debugPrint('❌ [NotificationInitializer] Error storing navigation data: $e');
    }
  }

  Future<void> _checkPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingNavigation = prefs.getString('pending_notification_navigation');
      
      if (pendingNavigation != null) {
        await prefs.remove('pending_notification_navigation');
        
        final data = jsonDecode(pendingNavigation);
        final senderId = data['senderId'] as String?;
        final chatRoomId = data['chatRoomId'] as String?;
        
        if (senderId != null && chatRoomId != null && mounted) {
          // Delay navigation slightly to ensure the app is fully ready
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _handleNotificationTap(senderId, chatRoomId);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [NotificationInitializer] Error checking pending navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔔🔔🔔 [NotificationInitializer] build called');
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        debugPrint('🔔🔔🔔 [NotificationInitializer] BlocListener triggered - state: ${state.status}');
        _checkAndInitialize();
      },
      child: widget.child,
    );
  }
}

/// Observer for app lifecycle changes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResumed;

  _AppLifecycleObserver({required this.onResumed});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('🔔 [AppLifecycleObserver] App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      debugPrint('🔔 [AppLifecycleObserver] App resumed - checking for pending navigation');
      await onResumed();
    }
  }
}

