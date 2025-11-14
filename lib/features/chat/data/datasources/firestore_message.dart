import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de mensaje
enum FirestoreMessageType {
  text,
  audio,
  image,
  images, // Múltiples imágenes
}

/// Modelo para representar un mensaje en Firestore
/// Colección: chat_rooms/{chatRoomId}/messages
class FirestoreMessage {
  final String messageId;
  final String senderId; // email del remitente
  final String receiverId; // email del receptor
  final FirestoreMessageType type;
  final String? textContent; // Para mensajes de texto
  final String? audioUrl; // Para mensajes de audio
  final List<String>? imageUrls; // Para imágenes
  final int? audioDuration; // Duración del audio en segundos
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata; // Datos adicionales

  FirestoreMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.textContent,
    this.audioUrl,
    this.imageUrls,
    this.audioDuration,
    required this.sentAt,
    this.isRead = false,
    this.readAt,
    this.metadata,
  });

  // Crear desde Firestore
  factory FirestoreMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      type: _parseMessageType(data['type']),
      textContent: data['textContent'],
      audioUrl: data['audioUrl'],
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      audioDuration: data['audioDuration'],
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'textContent': textContent,
      'audioUrl': audioUrl,
      'imageUrls': imageUrls,
      'audioDuration': audioDuration,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'metadata': metadata,
    };
  }

  // Parse tipo de mensaje
  static FirestoreMessageType _parseMessageType(dynamic type) {
    if (type == null) return FirestoreMessageType.text;

    switch (type.toString().toLowerCase()) {
      case 'text':
        return FirestoreMessageType.text;
      case 'audio':
        return FirestoreMessageType.audio;
      case 'image':
        return FirestoreMessageType.image;
      case 'images':
        return FirestoreMessageType.images;
      default:
        return FirestoreMessageType.text;
    }
  }

  // Obtener preview del mensaje para la lista
  String getPreview() {
    switch (type) {
      case FirestoreMessageType.text:
        return textContent ?? '';
      case FirestoreMessageType.audio:
        return '🎤 Audio message';
      case FirestoreMessageType.image:
        return '📷 Photo';
      case FirestoreMessageType.images:
        return '📷 ${imageUrls?.length ?? 0} photos';
    }
  }

  // Copiar con cambios
  FirestoreMessage copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    FirestoreMessageType? type,
    String? textContent,
    String? audioUrl,
    List<String>? imageUrls,
    int? audioDuration,
    DateTime? sentAt,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return FirestoreMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      audioDuration: audioDuration ?? this.audioDuration,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
