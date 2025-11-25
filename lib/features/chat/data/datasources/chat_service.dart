// chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:migozz_app/features/chat/data/datasources/firestore_message.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_rooms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Servicio completo de chat con Firebase (estructura Storage: chat/{chatId}/{audios|images}/file)
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // CHAT ROOMS

  Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final chatRoomId = ChatRoom.generateChatRoomId(
        currentUserId,
        otherUserId,
      );
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();

      if (!chatRoomDoc.exists) {
        final now = DateTime.now();
        await chatRoomRef.set({
          'participants': [currentUserId, otherUserId],
          'lastMessage': null,
          'lastMessageType': null,
          'lastMessageTime': Timestamp.fromDate(now),
          'unreadCount': {currentUserId: 0, otherUserId: 0},
          'hasResponded': {currentUserId: false, otherUserId: false},
          'createdAt': Timestamp.fromDate(now),
          'lastMessageData': null,
        });
        debugPrint('✅ [ChatService] Nueva sala creada: $chatRoomId');
      }

      return chatRoomId;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al crear/obtener sala: $e');
      rethrow;
    }
  }

  Stream<List<ChatRoom>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ChatRoom.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ChatRoom>> getNewChatsStream(String userId) => getUserChatsStream(
    userId,
  ).map((chats) => chats.where((c) => !c.userHasResponded(userId)).toList());

  Stream<List<ChatRoom>> getActiveChatsStream(String userId) =>
      getUserChatsStream(
        userId,
      ).map((chats) => chats.where((c) => c.userHasResponded(userId)).toList());

  // MENSAJES

  Future<void> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final messagesRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages');
      final now = DateTime.now();

      final message = FirestoreMessage(
        messageId: '',
        senderId: senderId,
        receiverId: receiverId,
        type: FirestoreMessageType.text,
        textContent: text,
        sentAt: now,
      );

      await messagesRef.add(message.toMap());

      await _updateChatRoom(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: text,
        lastMessageType: 'text',
        lastMessageTime: now,
      );

      debugPrint('✅ [ChatService] Mensaje de texto enviado');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al enviar texto: $e');
      rethrow;
    }
  }

  Future<void> sendAudioMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required File audioFile,
    required int durationSeconds,
  }) async {
    try {
      // Subir audio en: chat/{chatRoomId}/audios/<file>
      final url = await _uploadFileToChatFolder(
        file: audioFile,
        chatRoomId: chatRoomId,
        subfolder: 'audios',
      );

      final messagesRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages');
      final now = DateTime.now();

      final message = FirestoreMessage(
        messageId: '',
        senderId: senderId,
        receiverId: receiverId,
        type: FirestoreMessageType.audio,
        audioUrl: url,
        audioDuration: durationSeconds,
        sentAt: now,
      );

      await messagesRef.add(message.toMap());

      await _updateChatRoom(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: '🎤 Audio message',
        lastMessageType: 'audio',
        lastMessageTime: now,
        lastMessageData: {'audioUrl': url, 'duration': durationSeconds},
      );

      debugPrint('✅ [ChatService] Audio enviado');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al enviar audio: $e');
      rethrow;
    }
  }

  Future<void> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required List<File> imageFiles,
  }) async {
    try {
      final urls = <String>[];
      for (final img in imageFiles) {
        final url = await _uploadFileToChatFolder(
          file: img,
          chatRoomId: chatRoomId,
          subfolder: 'images',
        );
        urls.add(url);
      }

      final messagesRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages');
      final now = DateTime.now();

      final type = urls.length == 1
          ? FirestoreMessageType.image
          : FirestoreMessageType.images;

      final message = FirestoreMessage(
        messageId: '',
        senderId: senderId,
        receiverId: receiverId,
        type: type,
        imageUrls: urls,
        sentAt: now,
      );

      await messagesRef.add(message.toMap());

      await _updateChatRoom(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: urls.length == 1 ? '📷 Photo' : '📷 ${urls.length} photos',
        lastMessageType: 'image',
        lastMessageTime: now,
        lastMessageData: {'imageUrls': urls, 'count': urls.length},
      );

      debugPrint('✅ [ChatService] Imágenes enviadas');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al enviar imágenes: $e');
      rethrow;
    }
  }

  Stream<List<FirestoreMessage>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy(
          'sentAt',
          descending: true,
        ) // newest first (compatible con .reversed en UI)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FirestoreMessage.fromFirestore(d)).toList(),
        );
  }

  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true, 'readAt': Timestamp.now()});
      debugPrint('✅ [ChatService] Mensaje marcado como leído: $messageId');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al marcar mensaje leído: $e');
    }
  }

  Future<void> markAllMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final ref = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages');
      final unread = await ref
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();

      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });

      debugPrint('✅ [ChatService] Todos los mensajes marcados como leídos');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al marcar todos como leídos: $e');
    }
  }

  // HELPERS PRIVADOS

  /// Sube archivo a: chat/{chatRoomId}/{subfolder}/{timestamp_filename.ext}
  Future<String> _uploadFileToChatFolder({
    required File file,
    required String chatRoomId,
    required String subfolder, // 'images' o 'audios'
  }) async {
    try {
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final storagePath = 'chat/$chatRoomId/$subfolder/$filename';
      final ref = _storage.ref().child(storagePath);

      // Subida
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint(
        '✅ [ChatService] Archivo subido: $downloadUrl (path: $storagePath)',
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al subir archivo: $e');
      rethrow;
    }
  }

  Future<void> _updateChatRoom({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageTime,
    Map<String, dynamic>? lastMessageData,
  }) async {
    try {
      final ref = _firestore.collection('chat_rooms').doc(chatRoomId);
      final doc = await ref.get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};

      // Normalizar unreadCount
      final unread = <String, int>{};
      final rawUnread =
          (data['unreadCount'] as Map?)?.cast<String, dynamic>() ?? {};
      rawUnread.forEach((k, v) {
        if (v is int) {
          unread[k] = v;
        } else if (v is String) {
          unread[k] = int.tryParse(v) ?? 0;
        } else {
          unread[k] = 0;
        }
      });

      unread[receiverId] = (unread[receiverId] ?? 0) + 1;

      // Normalizar hasResponded
      final responded = <String, bool>{};
      final rawResp =
          (data['hasResponded'] as Map?)?.cast<String, dynamic>() ?? {};
      rawResp.forEach((k, v) {
        if (v is bool) {
          responded[k] = v;
        } else if (v is String) {
          responded[k] = v.toLowerCase() == 'true';
        } else {
          responded[k] = false;
        }
      });

      responded[senderId] = true;

      await ref.update({
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType,
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'lastMessageData': lastMessageData,
        'unreadCount': unread,
        'hasResponded': responded,
      });

      debugPrint('✅ [ChatService] Chat room actualizado');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al actualizar chat room: $e');
    }
  }

  // UTILIDADES

  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      debugPrint('✅ [ChatService] Mensaje eliminado');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al eliminar mensaje: $e');
    }
  }

  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();
      if (!doc.exists) return null;
      return ChatRoom.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ChatService] Error al obtener chat room: $e');
      return null;
    }
  }

  Future<void> deleteChat({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
      debugPrint('✅ [ChatService] Chat eliminado para el usuario');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al eliminar chat: $e');
    }
  }

  Stream<int> getTotalUnreadCountStream(String userId) {
    // ignore: avoid_types_as_parameter_names
    return getUserChatsStream(userId).map(
      // ignore: avoid_types_as_parameter_names
      (chats) => chats.fold<int>(0, (sum, c) => sum + c.getUnreadCount(userId)),
    );
  }

  // (Opcional) helper: descargar URL remota a archivo temporal
  // útil si tu reproductor necesita ruta local

  Future<File> downloadUrlToTempFile(String url, {String? filename}) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error descargando archivo: ${resp.statusCode}');
    }
    final bytes = resp.bodyBytes;
    final dir = await getTemporaryDirectory();
    final name =
        filename ??
        'file_${DateTime.now().millisecondsSinceEpoch}${p.extension(url)}';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }
}
