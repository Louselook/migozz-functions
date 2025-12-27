// chat_rooms.dart - VERSIÓN MEJORADA
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String chatRoomId;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, bool> hasResponded;
  final DateTime createdAt;
  final Map<String, dynamic>? lastMessageData;
  final List<String> deletedFor; // 🆕 Usuarios que eliminaron el chat
  final Map<String, List<String>>
  blockedBy; // 🆕 Bloqueos {userId: [bloqueados]}

  ChatRoom({
    required this.chatRoomId,
    required this.participants,
    this.lastMessage,
    this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.hasResponded,
    required this.createdAt,
    this.lastMessageData,
    this.deletedFor = const [],
    this.blockedBy = const {},
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // lastMessageTime seguro
    DateTime lastMessageTime;
    final rawLast = data['lastMessageTime'];
    if (rawLast is Timestamp) {
      lastMessageTime = rawLast.toDate();
    } else if (rawLast is DateTime) {
      lastMessageTime = rawLast;
    } else {
      lastMessageTime = DateTime.now();
    }

    // createdAt seguro
    DateTime createdAt;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else {
      createdAt = DateTime.now();
    }

    // unreadCount robusto
    final rawUnread =
        (data['unreadCount'] as Map?)?.cast<String, dynamic>() ?? {};
    final unreadCount = <String, int>{};
    rawUnread.forEach((k, v) {
      if (v is int) {
        unreadCount[k] = v;
      } else if (v is String) {
        unreadCount[k] = int.tryParse(v) ?? 0;
      } else {
        unreadCount[k] = 0;
      }
    });

    // hasResponded robusto
    final rawResponded =
        (data['hasResponded'] as Map?)?.cast<String, dynamic>() ?? {};
    final hasResponded = <String, bool>{};
    rawResponded.forEach((k, v) {
      if (v is bool) {
        hasResponded[k] = v;
      } else if (v is String) {
        hasResponded[k] = (v.toLowerCase() == 'true');
      } else {
        hasResponded[k] = false;
      }
    });

    // 🆕 deletedFor
    final deletedFor = List<String>.from(data['deletedFor'] ?? []);

    // 🆕 blockedBy
    final rawBlocked = data['blockedBy'] as Map<String, dynamic>? ?? {};
    final blockedBy = <String, List<String>>{};
    rawBlocked.forEach((k, v) {
      if (v is List) {
        blockedBy[k] = List<String>.from(v);
      }
    });

    return ChatRoom(
      chatRoomId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageType: data['lastMessageType'],
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      hasResponded: hasResponded,
      createdAt: createdAt,
      lastMessageData: data['lastMessageData'],
      deletedFor: deletedFor,
      blockedBy: blockedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'hasResponded': hasResponded,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageData': lastMessageData,
      'deletedFor': deletedFor,
      'blockedBy': blockedBy,
    };
  }

  static String generateChatRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  bool userHasResponded(String userId) {
    return hasResponded[userId] ?? false;
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // 🆕 Verificar si el chat fue eliminado por un usuario
  bool isDeletedFor(String userId) {
    return deletedFor.contains(userId);
  }

  // 🆕 Verificar si un usuario bloqueó a otro
  bool isBlocked(String blockerId, String blockedUserId) {
    return blockedBy[blockerId]?.contains(blockedUserId) ?? false;
  }
}
