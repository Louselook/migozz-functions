import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final UserMediaService _mediaService;

  UserService(this._mediaService);

  /// ---------------------------
  /// 🔹 MÉTODO GENÉRICO DE UPDATE
  /// ---------------------------
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    if (userId.isEmpty) {
      throw Exception('User ID inválido');
    }

    try {
      await _firestore.collection('users').doc(userId).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [UserService] Perfil actualizado: $fields');
    } catch (e, stack) {
      debugPrint('❌ [UserService] Error actualizando perfil: $e');
      debugPrint(stack.toString());
      throw Exception('Error actualizando perfil');
    }
  }

  /// ---------------------------
  /// 🔹 PICKER GENÉRICO
  /// ---------------------------
  Future<File?> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    return picked != null ? File(picked.path) : null;
  }

  /// ---------------------------
  /// 🔹 CAMBIAR AVATAR
  /// ---------------------------
  Future<String?> changeAvatar(String userId) async {
    try {
      final file = await _pickImage();
      if (file == null) {
        debugPrint('⚠️ [UserService] No se seleccionó imagen.');
        return null;
      }

      final urls = await _mediaService.uploadFiles(
        uid: userId,
        files: {MediaType.avatar: file},
      );

      final url = urls[MediaType.avatar];
      if (url == null) throw Exception('Upload no devolvió URL.');

      await updateUserProfile(userId, {'avatarUrl': url});

      debugPrint('✅ [UserService] Avatar actualizado: $url');
      return url;
    } catch (e, stack) {
      debugPrint('❌ [UserService] Error cambiando avatar: $e');
      debugPrint(stack.toString());
      throw Exception('Error cambiando avatar');
    }
  }
}
