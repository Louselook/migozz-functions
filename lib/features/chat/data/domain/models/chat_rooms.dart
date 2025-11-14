import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String chatRoomId; // formato: "user1_user2" (ordenado alfabéticamente)
  final List<String> participants; // [email1, email2]
  final String? lastMessage;
  final String? lastMessageType; // 'text', 'audio', 'image'
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount; // {email1: 2, email2: 0}
  final Map<String, bool> hasResponded; // {email1: true, email2: false}
  final DateTime createdAt;
  final Map<String, dynamic>?
  lastMessageData; // Datos adicionales del último mensaje

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
  });

  // Crear desde Firestore
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

    // unreadCount robusto: convierte valores a int o 0 si no se puede
    final rawUnread =
        (data['unreadCount'] as Map?)?.cast<String, dynamic>() ?? {};
    final unreadCount = <String, int>{};
    rawUnread.forEach((k, v) {
      if (v is int) {
        unreadCount[k] = v;
      } else if (v is String) {
        unreadCount[k] = int.tryParse(v) ?? 0;
      } else {
        // si v es Map u otro, fallback a 0
        unreadCount[k] = 0;
      }
    });

    // hasResponded robusto: convierte a bool o false
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
    );
  }

  // Convertir a Map para Firestore
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
    };
  }

  // Generar ID de chat room ordenado
  static String generateChatRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Verificar si un usuario ha respondido
  bool userHasResponded(String userId) {
    return hasResponded[userId] ?? false;
  }

  // Obtener mensajes no leídos para un usuario
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Obtener el otro participante
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }
}
