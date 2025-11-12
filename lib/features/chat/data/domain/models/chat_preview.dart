/// Modelo simple para representar un chat en la lista (solo UI)
class ChatPreview {
  final String userId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isVerified;
  final bool isOnline;

  ChatPreview({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isVerified = false,
    this.isOnline = false,
  });
}
