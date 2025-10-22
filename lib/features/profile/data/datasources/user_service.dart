import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final UserMediaService _mediaService; // 🔹 el tuyo

  UserService(this._mediaService);

  /// 🔹 Actualiza cualquier campo parcial del usuario
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [UserService] Perfil actualizado: $fields');
    } catch (e) {
      debugPrint('❌ [UserService] Error actualizando perfil: $e');
      rethrow;
    }
  }

  /// 🔹 Cambia el avatar y actualiza Firestore automáticamente
  Future<String?> changeAvatar(String userId) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        debugPrint('⚠️ [UserService] No se seleccionó imagen.');
        return null;
      }

      final urls = await _mediaService.uploadFiles(
        uid: userId,
        files: {MediaType.avatar: File(picked.path)},
      );

      final newUrl = urls[MediaType.avatar];
      if (newUrl == null) {
        throw Exception('No se recibió URL del servidor.');
      }

      await updateUserProfile(userId, {'avatarUrl': newUrl});
      debugPrint('✅ [UserService] Avatar actualizado correctamente: $newUrl');
      return newUrl;
    } catch (e) {
      debugPrint('❌ [UserService] Error cambiando avatar: $e');
      rethrow;
    }
  }

  // 🔹 Cambia nota de voz (similar al avatar)
  // Future<String?> changeVoiceNote(String userId) async {
  //   try {
  //     final picked = await _picker.pickVideo(source: ImageSource.gallery);

  //     if (picked == null) {
  //       debugPrint('⚠️ [UserService] No se seleccionó archivo de voz.');
  //       return null;
  //     }

  //     final urls = await _mediaService.uploadFiles(
  //       uid: userId,
  //       files: {MediaType.voice: File(picked.path)},
  //     );

  //     final newUrl = urls[MediaType.voice];
  //     if (newUrl == null) {
  //       throw Exception('No se recibió URL del servidor.');
  //     }

  //     await updateUserProfile(userId, {'voiceNoteUrl': newUrl});
  //     debugPrint('✅ [UserService] Voice note actualizada: $newUrl');
  //     return newUrl;
  //   } catch (e) {
  //     debugPrint('❌ [UserService] Error cambiando voice note: $e');
  //     rethrow;
  //   }
  // }
}
