/// Model class for chat notification data
/// Named ChatNotificationModel to avoid conflict with awesome_notifications
class ChatNotificationModel {
  final String id;
  final String title;
  final String body;
  final String senderId;
  final String chatRoomId;
  final String? senderName;
  final String? senderAvatar;
  final DateTime timestamp;
  final bool isRead;

  ChatNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.senderId,
    required this.chatRoomId,
    this.senderName,
    this.senderAvatar,
    required this.timestamp,
    this.isRead = false,
  });

  /// Create from JSON
  factory ChatNotificationModel.fromJson(Map<String, dynamic> json) {
    return ChatNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      senderId: json['senderId'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'senderId': senderId,
      'chatRoomId': chatRoomId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// Create a copy with updated fields
  ChatNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? senderId,
    String? chatRoomId,
    String? senderName,
    String? senderAvatar,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      senderId: senderId ?? this.senderId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  @override
  String toString() {
    return 'ChatNotificationModel(id: $id, title: $title, body: $body, senderId: $senderId, isRead: $isRead)';
  }
}

