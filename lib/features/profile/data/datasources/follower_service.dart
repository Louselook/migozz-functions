import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/data/domain/models/follower_dto.dart';

/// Servicio para manejar operaciones de seguidores en Firebase
///
/// IMPORTANTE: Este servicio usa UIDs de Firebase Auth (no emails) para identificar usuarios.
/// Los documentos de followers se almacenan en:
/// - users/{userId}/followerList/{followerId}
/// - users/{userId}/followingList/{followingId}
/// Donde userId, followerId y followingId son UIDs de Firebase Auth.
class FollowerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache de UIDs por email para evitar consultas repetidas
  final Map<String, String> _uidCache = {};

  /// ---------------------------
  /// 🔹 OBTENER UID POR EMAIL
  /// ---------------------------
  /// Busca el UID de un usuario en Firestore basándose en su email.
  /// El documento del usuario está almacenado con su UID como ID del documento.
  Future<String?> getUserIdByEmail(String email) async {
    if (email.isEmpty) return null;

    // Verificar cache primero
    if (_uidCache.containsKey(email)) {
      return _uidCache[email];
    }

    try {
      // Buscar en la colección users donde email == email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final uid = querySnapshot.docs.first.id;
        _uidCache[email] = uid; // Cachear para uso futuro
        debugPrint('✅ [FollowerService] UID encontrado para $email: $uid');
        return uid;
      }

      debugPrint(
        '⚠️ [FollowerService] No se encontró usuario con email: $email',
      );
      return null;
    } catch (e) {
      debugPrint('❌ [FollowerService] Error buscando UID por email: $e');
      return null;
    }
  }

  /// Limpia la cache de UIDs (útil para pruebas o logout)
  void clearUidCache() {
    _uidCache.clear();
  }

  /// ---------------------------
  /// 🔹 SEGUIR A UN USUARIO
  /// ---------------------------
  /// Agrega el usuario actual a la lista de seguidores del otro usuario
  /// y agrega el otro usuario a la lista de siguiendo del usuario actual
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      throw Exception('IDs de usuario inválidos');
    }

    if (currentUserId == targetUserId) {
      throw Exception('No puedes seguirte a ti mismo');
    }

    try {
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // 1. Agregar a followerList del usuario objetivo
      // users/{targetUserId}/followerList/{currentUserId}
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followerList')
          .doc(currentUserId);

      batch.set(followerRef, {'followingDate': timestamp});

      // 2. Agregar a followingList del usuario actual
      // users/{currentUserId}/followingList/{targetUserId}
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followingList')
          .doc(targetUserId);

      batch.set(followingRef, {'followingDate': timestamp});

      // 3. Create a notification document for the target user
      final notificationRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'type': 'follow',
        'fromUserId': currentUserId,
        'timestamp': timestamp,
        'isRead': false,
      });

      await batch.commit();

      debugPrint(
        '✅ [FollowerService] $currentUserId ahora sigue a $targetUserId',
      );

      // 4. Send push notification to target user (async, don't wait)
      _sendFollowPushNotification(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
    } catch (e, stack) {
      debugPrint('❌ [FollowerService] Error siguiendo usuario: $e');
      debugPrint(stack.toString());
      throw Exception('Error al seguir usuario');
    }
  }

  /// ---------------------------
  /// 🔹 SEND FOLLOW PUSH NOTIFICATION
  /// ---------------------------
  /// Sends a push notification to the target user when someone follows them
  Future<void> _sendFollowPushNotification({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Get current user info for the notification
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists) {
        debugPrint(
          '⚠️ [FollowerService] Current user not found for notification',
        );
        return;
      }

      final currentUserData = currentUserDoc.data()!;
      final followerName =
          currentUserData['displayName']?.toString() ??
          currentUserData['username']?.toString() ??
          'Someone';
      currentUserData['avatarUrl']?.toString();

      // Get target user's FCM token
      final targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!targetUserDoc.exists) {
        debugPrint(
          '⚠️ [FollowerService] Target user not found for notification',
        );
        return;
      }

      final targetUserData = targetUserDoc.data()!;
      final fcmToken = targetUserData['lastFcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ [FollowerService] Target user has no FCM token');
        return;
      }

      // Send push notification via FCM HTTP v1 API
      // Note: This requires a server-side implementation or Cloud Functions
      // For now, we save the notification to Firestore and the user will see it
      // when they open the app or via a Cloud Function trigger
      debugPrint(
        '🔔 [FollowerService] Follow notification saved for $targetUserId from $followerName',
      );
      debugPrint(
        '🔔 [FollowerService] FCM token available: ${fcmToken.substring(0, 20)}...',
      );

      // The actual push notification should be sent via Cloud Functions
      // triggered by the notification document creation above
    } catch (e) {
      debugPrint('❌ [FollowerService] Error sending follow notification: $e');
    }
  }

  /// ---------------------------
  /// 🔹 DEJAR DE SEGUIR A UN USUARIO
  /// ---------------------------
  /// Elimina el usuario actual de la lista de seguidores del otro usuario
  /// y elimina el otro usuario de la lista de siguiendo del usuario actual
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      throw Exception('IDs de usuario inválidos');
    }

    try {
      final batch = _firestore.batch();

      // 1. Eliminar de followerList del usuario objetivo
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followerList')
          .doc(currentUserId);

      batch.delete(followerRef);

      // 2. Eliminar de followingList del usuario actual
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followingList')
          .doc(targetUserId);

      batch.delete(followingRef);

      await batch.commit();

      debugPrint(
        '✅ [FollowerService] $currentUserId dejó de seguir a $targetUserId',
      );
    } catch (e, stack) {
      debugPrint('❌ [FollowerService] Error dejando de seguir: $e');
      debugPrint(stack.toString());
      throw Exception('Error al dejar de seguir usuario');
    }
  }

  /// ---------------------------
  /// 🔹 VERIFICAR SI SIGUE A UN USUARIO
  /// ---------------------------
  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followingList')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ [FollowerService] Error verificando follow: $e');
      return false;
    }
  }

  /// ---------------------------
  /// 🔹 OBTENER LISTA DE SEGUIDORES
  /// ---------------------------
  Future<List<FollowerDTO>> getFollowers(String userId) async {
    if (userId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followerList')
          .orderBy('followingDate', descending: true)
          .get();

      final followers = <FollowerDTO>[];

      for (final doc in snapshot.docs) {
        final follower = FollowerDTO.fromMap(doc.id, doc.data());
        // Obtener información adicional del usuario
        final enrichedFollower = await _enrichFollowerWithUserInfo(follower);
        followers.add(enrichedFollower);
      }

      debugPrint(
        '✅ [FollowerService] ${followers.length} seguidores obtenidos',
      );
      return followers;
    } catch (e, stack) {
      debugPrint('❌ [FollowerService] Error obteniendo seguidores: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  /// ---------------------------
  /// 🔹 OBTENER LISTA DE SIGUIENDO
  /// ---------------------------
  Future<List<FollowerDTO>> getFollowing(String userId) async {
    if (userId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followingList')
          .orderBy('followingDate', descending: true)
          .get();

      final following = <FollowerDTO>[];

      for (final doc in snapshot.docs) {
        final follow = FollowerDTO.fromMap(doc.id, doc.data());
        // Obtener información adicional del usuario
        final enrichedFollow = await _enrichFollowerWithUserInfo(follow);
        following.add(enrichedFollow);
      }

      debugPrint('✅ [FollowerService] ${following.length} siguiendo obtenidos');
      return following;
    } catch (e, stack) {
      debugPrint('❌ [FollowerService] Error obteniendo siguiendo: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  /// ---------------------------
  /// 🔹 OBTENER CONTADORES
  /// ---------------------------
  Future<int> getFollowersCount(String userId) async {
    if (userId.isEmpty) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followerList')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [FollowerService] Error contando seguidores: $e');
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    if (userId.isEmpty) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followingList')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [FollowerService] Error contando siguiendo: $e');
      return 0;
    }
  }

  /// ---------------------------
  /// 🔹 STREAM DE ESTADO DE FOLLOW
  /// ---------------------------
  Stream<bool> watchIsFollowing({
    required String currentUserId,
    required String targetUserId,
  }) {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followingList')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// ---------------------------
  /// 🔹 STREAM DE CONTADORES
  /// ---------------------------
  Stream<int> watchFollowersCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followerList')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchFollowingCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followingList')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ---------------------------
  /// 🔹 HELPER: ENRIQUECER CON INFO DE USUARIO
  /// ---------------------------
  Future<FollowerDTO> _enrichFollowerWithUserInfo(FollowerDTO follower) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(follower.oderId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return follower.copyWithUserInfo(
          displayName: data['displayName']?.toString(),
          username: data['username']?.toString(),
          avatarUrl: data['avatarUrl']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ [FollowerService] Error obteniendo info de usuario: $e');
    }

    return follower;
  }

  /// ---------------------------
  /// 🔹 VERIFICAR FOLLOW MUTUO
  /// ---------------------------
  Future<bool> isMutualFollow({
    required String userId1,
    required String userId2,
  }) async {
    if (userId1.isEmpty || userId2.isEmpty) return false;

    try {
      final results = await Future.wait([
        isFollowing(currentUserId: userId1, targetUserId: userId2),
        isFollowing(currentUserId: userId2, targetUserId: userId1),
      ]);

      return results[0] && results[1];
    } catch (e) {
      debugPrint('❌ [FollowerService] Error verificando follow mutuo: $e');
      return false;
    }
  }

  /// ---------------------------
  /// 🔹 ELIMINAR SEGUIDOR (desde la lista de seguidores)
  /// ---------------------------
  /// Cuando el usuario quiere eliminar a alguien que lo sigue
  Future<void> removeFollower({
    required String currentUserId,
    required String followerUserId,
  }) async {
    if (currentUserId.isEmpty || followerUserId.isEmpty) {
      throw Exception('IDs de usuario inválidos');
    }

    try {
      final batch = _firestore.batch();

      // 1. Eliminar de followerList del usuario actual
      final followerRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followerList')
          .doc(followerUserId);

      batch.delete(followerRef);

      // 2. Eliminar de followingList del seguidor
      final followingRef = _firestore
          .collection('users')
          .doc(followerUserId)
          .collection('followingList')
          .doc(currentUserId);

      batch.delete(followingRef);

      await batch.commit();

      debugPrint(
        '✅ [FollowerService] $followerUserId eliminado de seguidores de $currentUserId',
      );
    } catch (e, stack) {
      debugPrint('❌ [FollowerService] Error eliminando seguidor: $e');
      debugPrint(stack.toString());
      throw Exception('Error al eliminar seguidor');
    }
  }
}
