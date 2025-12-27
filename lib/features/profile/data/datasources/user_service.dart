import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/camera_permission_handler.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  /// 🔹 CAMBIAR AVATAR
  /// ---------------------------
  /// Shows a bottom sheet to select image source (camera or gallery)
  /// Uses proper permission handling for camera access
  Future<String?> changeAvatar(String userId, BuildContext context) async {
    try {
      // Show bottom sheet to select source
      final imagePath = await _showImageSourceBottomSheet(context);

      if (imagePath == null) {
        debugPrint('⚠️ [UserService] No se seleccionó imagen.');
        return null;
      }

      final file = File(imagePath);
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

  /// Show bottom sheet to select image source
  Future<String?> _showImageSourceBottomSheet(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.purple),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final path = await CameraPermissionHandler.openCamera(
                      imageQuality: 40,
                      context: context,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.purple),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final path = await CameraPermissionHandler.openGallery(
                      imageQuality: 40,
                      context: context,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.grey),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
