import 'package:migozz_app/features/chat/data/datasources/firestore_message.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';

/// Adaptador para convertir entre FirestoreMessage (backend) y Map (UI)
class MessageAdapter {
  /// Convertir FirestoreMessage a Map para el controller
  static Map<String, dynamic> toUiMessage(
    FirestoreMessage firestoreMessage,
    String currentUserId,
  ) {
    final isOther = firestoreMessage.senderId != currentUserId;
    final time = _formatTime(firestoreMessage.sentAt);

    switch (firestoreMessage.type) {
      case FirestoreMessageType.text:
        return {
          'other': isOther,
          'type': MessageType.text,
          'text': firestoreMessage.textContent ?? '',
          'time': time,
          'messageId': firestoreMessage.messageId,
          'senderId': firestoreMessage.senderId,
          'receiverId': firestoreMessage.receiverId,
        };

      case FirestoreMessageType.audio:
        return {
          'other': isOther,
          'type': MessageType.audio,
          'audio': firestoreMessage.audioUrl,
          'time': time,
          'duration': firestoreMessage.audioDuration,
          'messageId': firestoreMessage.messageId,
          'senderId': firestoreMessage.senderId,
          'receiverId': firestoreMessage.receiverId,
        };

      case FirestoreMessageType.image:
        return {
          'other': isOther,
          'type': MessageType.pictureCard,
          'pictures': [
            {
              'imageUrl': firestoreMessage.imageUrls?.first ?? '',
              'label': 'Photo',
            },
          ],
          'time': time,
          'messageId': firestoreMessage.messageId,
          'senderId': firestoreMessage.senderId,
          'receiverId': firestoreMessage.receiverId,
        };

      case FirestoreMessageType.images:
        return {
          'other': isOther,
          'type': MessageType.pictureCard,
          'pictures':
              firestoreMessage.imageUrls
                  ?.map((url) => {'imageUrl': url, 'label': 'Photo'})
                  .toList() ??
              [],
          'time': time,
          'messageId': firestoreMessage.messageId,
          'senderId': firestoreMessage.senderId,
          'receiverId': firestoreMessage.receiverId,
        };
    }
  }

  /// Formatear hora del mensaje
  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Convertir múltiples mensajes de Firestore a UI
  static List<Map<String, dynamic>> toUiMessages(
    List<FirestoreMessage> firestoreMessages,
    String currentUserId,
  ) {
    return firestoreMessages
        .map((msg) => toUiMessage(msg, currentUserId))
        .toList();
  }
}
