// chat_service.dart - VERSIÓN MEJORADA
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

/// Servicio completo de chat con Firebase - MEJORADO
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== CHAT ROOMS ====================

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
          'deletedFor': [], // 🆕 Lista de usuarios que eliminaron el chat
          'deletedAt':
              {}, // 🆕 {userId: timestamp} - Cuándo eliminó cada usuario
          'blockedBy': {}, // 🆕 {userId: [listaDeUsuariosBloqueados]}
        });
        debugPrint('✅ [ChatService] Nueva sala creada: $chatRoomId');
      }

      return chatRoomId;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al crear/obtener sala: $e');
      rethrow;
    }
  }

  /// Stream de chats del usuario (excluyendo los eliminados)
  Stream<List<ChatRoom>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) {
          debugPrint(
            '📋 [ChatService] getUserChatsStream - Total docs: ${snap.docs.length}',
          );

          final allChats = snap.docs
              .map((d) => ChatRoom.fromFirestore(d))
              .toList();

          // Debug: mostrar deletedFor de cada chat
          for (final chat in allChats) {
            debugPrint(
              '📋 [ChatService] Chat ${chat.chatRoomId} - deletedFor: ${chat.deletedFor}',
            );
          }

          // Filtrar chats eliminados por este usuario
          final filtered = allChats
              .where((chat) => !chat.isDeletedFor(userId))
              .toList();

          debugPrint(
            '📋 [ChatService] Chats después de filtrar eliminados: ${filtered.length}',
          );

          return filtered;
        });
  }

  Stream<List<ChatRoom>> getNewChatsStream(String userId) => getUserChatsStream(
    userId,
  ).map((chats) => chats.where((c) => !c.userHasResponded(userId)).toList());

  Stream<List<ChatRoom>> getActiveChatsStream(String userId) =>
      getUserChatsStream(
        userId,
      ).map((chats) => chats.where((c) => c.userHasResponded(userId)).toList());

  // ==================== MENSAJES ====================

  Future<void> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      // 🆕 Verificar si está bloqueado
      if (await _isBlocked(chatRoomId, senderId, receiverId)) {
        debugPrint('⚠️ [ChatService] Mensaje no enviado: usuario bloqueado');
        return; // El mensaje no se envía pero el usuario no lo sabe
      }

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
      // 🆕 Verificar bloqueo
      if (await _isBlocked(chatRoomId, senderId, receiverId)) {
        debugPrint('⚠️ [ChatService] Audio no enviado: usuario bloqueado');
        return;
      }

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
      // 🆕 Verificar bloqueo
      if (await _isBlocked(chatRoomId, senderId, receiverId)) {
        debugPrint('⚠️ [ChatService] Imagen no enviada: usuario bloqueado');
        return;
      }

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

  /// 🆕 Stream de mensajes con filtro de bloqueados
  Stream<List<FirestoreMessage>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FirestoreMessage.fromFirestore(d)).toList(),
        );
  }

  /// 🆕 Stream de mensajes filtrados por deletedAt del usuario (estilo WhatsApp)
  /// Solo muestra mensajes enviados DESPUÉS de la última eliminación
  Stream<List<FirestoreMessage>> getMessagesStreamForUser({
    required String chatRoomId,
    required String userId,
  }) {
    // Primero obtenemos el deletedAt del chat room
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots().asyncExpand((
      chatDoc,
    ) {
      final data = chatDoc.data() ?? {};
      final deletedAtMap = data['deletedAt'] as Map<String, dynamic>? ?? {};

      // Obtener timestamp de eliminación del usuario
      DateTime? userDeletedAt;
      if (deletedAtMap.containsKey(userId)) {
        final raw = deletedAtMap[userId];
        if (raw is Timestamp) {
          userDeletedAt = raw.toDate();
        }
      }

      debugPrint(
        '🔍 [ChatService] getMessagesStreamForUser - userId: $userId, deletedAt: $userDeletedAt',
      );

      // Escuchar mensajes en tiempo real y filtrar
      return _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .snapshots()
          .map((messagesSnap) {
            final allMessages = messagesSnap.docs
                .map((d) => FirestoreMessage.fromFirestore(d))
                .toList();

            // Filtrar mensajes anteriores a deletedAt
            if (userDeletedAt != null) {
              final filtered = allMessages.where((msg) {
                return msg.sentAt.isAfter(userDeletedAt!);
              }).toList();
              debugPrint(
                '🔍 [ChatService] Mensajes filtrados: ${filtered.length} de ${allMessages.length}',
              );
              return filtered;
            }

            return allMessages;
          });
    });
  }

  /// 🆕 MEJORADO: Marcar mensaje como leído Y actualizar contador
  Future<void> markMessageAsRead({
    required String chatRoomId,
    required String messageId,
    required String userId, // 🆕 Necesario para actualizar contador
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true, 'readAt': Timestamp.now()});

      // 🆕 Decrementar contador de no leídos
      await _decrementUnreadCount(chatRoomId, userId);

      debugPrint('✅ [ChatService] Mensaje marcado como leído: $messageId');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al marcar mensaje leído: $e');
    }
  }

  /// 🆕 MEJORADO: Marcar todos los mensajes como leídos Y resetear contador
  Future<void> markAllMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      debugPrint(
        '🔍 [ChatService] Buscando mensajes no leídos para: $userId en sala: $chatRoomId',
      );

      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final messagesRef = chatRoomRef.collection('messages');

      // Obtener TODOS los mensajes recibidos por este usuario
      final allReceived = await messagesRef
          .where('receiverId', isEqualTo: userId)
          .get();

      debugPrint(
        '📩 [ChatService] Total mensajes recibidos: ${allReceived.docs.length}',
      );

      // Filtrar los no leídos manualmente (más robusto)
      final unreadDocs = allReceived.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] != true;
      }).toList();

      debugPrint('📬 [ChatService] Mensajes no leídos: ${unreadDocs.length}');

      if (unreadDocs.isNotEmpty) {
        // Marcar todos como leídos en batch
        final batch = _firestore.batch();
        final now = Timestamp.now();

        for (final doc in unreadDocs) {
          batch.update(doc.reference, {'isRead': true, 'readAt': now});
        }
        await batch.commit();
        debugPrint(
          '✅ [ChatService] ${unreadDocs.length} mensajes marcados como leídos',
        );
      }

      // 🆕 FIX: Actualizar el mapa completo para evitar problemas con emails que tienen puntos
      final chatRoomDoc = await chatRoomRef.get();
      final data = chatRoomDoc.data() ?? {};

      // Debug: ver qué hay actualmente en unreadCount
      debugPrint('🔍 [ChatService] unreadCount actual: ${data['unreadCount']}');

      // Reconstruir el mapa limpio (solo con los participantes correctos)
      final participants = List<String>.from(data['participants'] ?? []);
      final newUnreadCount = <String, int>{};
      for (final p in participants) {
        newUnreadCount[p] = (p == userId)
            ? 0
            : _getUnreadValue(data['unreadCount'], p);
      }

      await chatRoomRef.update({'unreadCount': newUnreadCount});
      debugPrint('✅ [ChatService] Contador actualizado: $newUnreadCount');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al marcar todos como leídos: $e');
    }
  }

  /// Helper para obtener el valor de unread de forma segura
  int _getUnreadValue(dynamic unreadMap, String key) {
    if (unreadMap == null || unreadMap is! Map) return 0;
    final value = unreadMap[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ==================== FUNCIONES NUEVAS ====================

  /// 🆕 Bloquear usuario
  Future<void> blockUser({
    required String chatRoomId,
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final doc = await chatRoomRef.get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final blockedBy = Map<String, dynamic>.from(data['blockedBy'] ?? {});

      // Añadir el usuario bloqueado a la lista del usuario actual
      if (blockedBy[userId] == null) {
        blockedBy[userId] = [blockedUserId];
      } else {
        final List<dynamic> blocked = List.from(blockedBy[userId]);
        if (!blocked.contains(blockedUserId)) {
          blocked.add(blockedUserId);
          blockedBy[userId] = blocked;
        }
      }

      await chatRoomRef.update({'blockedBy': blockedBy});
      debugPrint('✅ [ChatService] Usuario bloqueado: $blockedUserId');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al bloquear usuario: $e');
      rethrow;
    }
  }

  /// 🆕 Desbloquear usuario
  Future<void> unblockUser({
    required String chatRoomId,
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final doc = await chatRoomRef.get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final blockedBy = Map<String, dynamic>.from(data['blockedBy'] ?? {});

      if (blockedBy[userId] != null) {
        final List<dynamic> blocked = List.from(blockedBy[userId]);
        blocked.remove(blockedUserId);
        blockedBy[userId] = blocked;

        await chatRoomRef.update({'blockedBy': blockedBy});
        debugPrint('✅ [ChatService] Usuario desbloqueado: $blockedUserId');
      }
    } catch (e) {
      debugPrint('❌ [ChatService] Error al desbloquear usuario: $e');
    }
  }

  /// 🆕 Verificar si un usuario está bloqueado
  Future<bool> isUserBlocked({
    required String chatRoomId,
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final blockedBy = Map<String, dynamic>.from(data['blockedBy'] ?? {});

      // Verificar si userId bloqueó a otherUserId
      if (blockedBy[userId] != null) {
        final List<dynamic> blocked = List.from(blockedBy[userId]);
        return blocked.contains(otherUserId);
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al verificar bloqueo: $e');
      return false;
    }
  }

  /// 🆕 Verificar si el usuario actual fue bloqueado por el otro usuario
  Future<bool> isBlockedByOtherUser({
    required String chatRoomId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final blockedBy = Map<String, dynamic>.from(data['blockedBy'] ?? {});

      // Verificar si otherUserId bloqueó a currentUserId
      if (blockedBy[otherUserId] != null) {
        final List<dynamic> blocked = List.from(blockedBy[otherUserId]);
        return blocked.contains(currentUserId);
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al verificar si fue bloqueado: $e');
      return false;
    }
  }

  /// 🆕 Reportar usuario
  /// Guarda el reporte en una colección 'reports' para revisión del admin
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String chatRoomId,
    required String reason,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'chatRoomId': chatRoomId,
        'reason': reason,
        'status': 'pending', // pending, reviewed, resolved, dismissed
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      debugPrint(
        '✅ [ChatService] Reporte enviado para usuario: $reportedUserId',
      );
    } catch (e) {
      debugPrint('❌ [ChatService] Error al enviar reporte: $e');
      rethrow;
    }
  }

  /// 🆕 Eliminar chat para un usuario específico (estilo WhatsApp)
  /// Guarda el timestamp de eliminación para filtrar mensajes antiguos
  Future<void> deleteChatForUser({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Primero obtener el deletedAt actual
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();
      final data = doc.data() ?? {};
      final deletedAt = Map<String, dynamic>.from(data['deletedAt'] ?? {});

      // Agregar/actualizar timestamp para este usuario
      deletedAt[userId] = Timestamp.now();

      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
        'deletedAt': deletedAt, // 🆕 Guardar mapa completo
      });
      debugPrint(
        '✅ [ChatService] Chat eliminado para el usuario: $userId (con timestamp: ${deletedAt[userId]})',
      );
    } catch (e) {
      debugPrint('❌ [ChatService] Error al eliminar chat: $e');
      rethrow;
    }
  }

  /// 🆕 Verificar si ambos usuarios eliminaron el chat (para eliminación definitiva)
  Future<bool> isChatDeletedByBoth({
    required String chatRoomId,
    required List<String> participants,
  }) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);

      // Verificar si ambos participantes están en deletedFor
      return participants.every((p) => deletedFor.contains(p));
    } catch (e) {
      debugPrint('❌ [ChatService] Error al verificar eliminación: $e');
      return false;
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Verificar si el remitente está bloqueado por el receptor
  Future<bool> _isBlocked(
    String chatRoomId,
    String senderId,
    String receiverId,
  ) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final blockedBy = Map<String, dynamic>.from(data['blockedBy'] ?? {});

      // Verificar si el receptor bloqueó al remitente
      if (blockedBy[receiverId] != null) {
        final List<dynamic> blocked = List.from(blockedBy[receiverId]);
        return blocked.contains(senderId);
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ChatService] Error al verificar bloqueo: $e');
      return false;
    }
  }

  /// 🆕 Decrementar contador de no leídos
  Future<void> _decrementUnreadCount(String chatRoomId, String userId) async {
    try {
      final ref = _firestore.collection('chat_rooms').doc(chatRoomId);
      final doc = await ref.get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});

      int currentCount = 0;
      final rawCount = unreadCount[userId];
      if (rawCount is int) {
        currentCount = rawCount;
      } else if (rawCount is String) {
        currentCount = int.tryParse(rawCount) ?? 0;
      }

      if (currentCount > 0) {
        // 🆕 FIX: Actualizar el mapa completo para evitar problemas con emails que tienen puntos
        unreadCount[userId] = currentCount - 1;
        await ref.update({'unreadCount': unreadCount});
      }
    } catch (e) {
      debugPrint('❌ [ChatService] Error al decrementar contador: $e');
    }
  }

  Future<String> _uploadFileToChatFolder({
    required File file,
    required String chatRoomId,
    required String subfolder,
  }) async {
    try {
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final storagePath = 'chat/$chatRoomId/$subfolder/$filename';
      final ref = _storage.ref().child(storagePath);

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

      // 🆕 Solo incrementar si el receptor no tiene el chat abierto
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

      // 🆕 Restaurar chat para AMBOS usuarios si estaban en deletedFor
      // - Si el SENDER había eliminado el chat y ahora escribe, debe volver a verlo
      // - Si el RECEIVER había eliminado el chat y le escriben, debe volver a verlo
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);
      debugPrint(
        '🔍 [ChatService] _updateChatRoom - senderId: $senderId, receiverId: $receiverId',
      );
      debugPrint(
        '🔍 [ChatService] _updateChatRoom - deletedFor ANTES: $deletedFor',
      );

      // Restaurar para el sender (si eliminó el chat pero ahora escribe)
      if (deletedFor.contains(senderId)) {
        deletedFor.remove(senderId);
        debugPrint('🔄 [ChatService] Chat restaurado para SENDER: $senderId');
      }

      // Restaurar para el receiver (si eliminó el chat pero le escriben)
      if (deletedFor.contains(receiverId)) {
        deletedFor.remove(receiverId);
        debugPrint(
          '🔄 [ChatService] Chat restaurado para RECEIVER: $receiverId',
        );
      }

      debugPrint(
        '🔍 [ChatService] _updateChatRoom - deletedFor DESPUÉS: $deletedFor',
      );

      await ref.update({
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType,
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'lastMessageData': lastMessageData,
        'unreadCount': unread,
        'hasResponded': responded,
        'deletedFor': deletedFor, // 🆕 Actualizar lista de eliminados
      });

      debugPrint('✅ [ChatService] Chat room actualizado');
    } catch (e) {
      debugPrint('❌ [ChatService] Error al actualizar chat room: $e');
    }
  }

  // ==================== UTILIDADES ====================

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

  Stream<int> getTotalUnreadCountStream(String userId) {
    return getUserChatsStream(userId).map(
      // ignore: avoid_types_as_parameter_names
      (chats) => chats.fold<int>(0, (sum, c) => sum + c.getUnreadCount(userId)),
    );
  }

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
