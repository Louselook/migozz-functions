import 'package:flutter/foundation.dart';

/// Singleton service to track which chat conversation the user is currently viewing.
/// This is used to suppress notifications when the user is already in the chat.
class ActiveChatManager extends ChangeNotifier {
  static final ActiveChatManager _instance = ActiveChatManager._internal();
  factory ActiveChatManager() => _instance;
  ActiveChatManager._internal();

  static ActiveChatManager get instance => _instance;

  /// The ID of the user the current user is chatting with (null if not in a chat)
  String? _activeChatUserId;

  /// The chat room ID of the active chat (null if not in a chat)
  String? _activeChatRoomId;

  /// Get the active chat user ID
  String? get activeChatUserId => _activeChatUserId;

  /// Get the active chat room ID
  String? get activeChatRoomId => _activeChatRoomId;

  /// Check if user is currently in a chat with a specific user
  bool isInChatWith(String userId) {
    return _activeChatUserId == userId;
  }

  /// Check if user is currently in a specific chat room
  bool isInChatRoom(String chatRoomId) {
    return _activeChatRoomId == chatRoomId;
  }

  /// Check if user is in any chat
  bool get isInAnyChat => _activeChatUserId != null;

  /// Set the active chat when user enters a chat screen
  void enterChat({
    required String otherUserId,
    required String chatRoomId,
  }) {
    _activeChatUserId = otherUserId;
    _activeChatRoomId = chatRoomId;
    debugPrint('📱 [ActiveChatManager] Entered chat with: $otherUserId (room: $chatRoomId)');
    notifyListeners();
  }

  /// Clear the active chat when user leaves a chat screen
  void leaveChat() {
    final previousUser = _activeChatUserId;
    _activeChatUserId = null;
    _activeChatRoomId = null;
    debugPrint('📱 [ActiveChatManager] Left chat with: $previousUser');
    notifyListeners();
  }

  /// Check if a notification should be shown for a message from a specific user
  bool shouldShowNotification({
    required String senderId,
    String? chatRoomId,
  }) {
    // Don't show notification if user is in chat with the sender
    if (_activeChatUserId == senderId) {
      debugPrint('🔕 [ActiveChatManager] Suppressing notification - user is in chat with sender');
      return false;
    }

    // Also check by chat room ID if provided
    if (chatRoomId != null && _activeChatRoomId == chatRoomId) {
      debugPrint('🔕 [ActiveChatManager] Suppressing notification - user is in the same chat room');
      return false;
    }

    return true;
  }
}

