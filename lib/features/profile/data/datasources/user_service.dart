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
                      imageQuality: 85,
                      context: context,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.purple,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final path = await CameraPermissionHandler.openGallery(
                      imageQuality: 85,
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

  /// ---------------------------
  /// 🔹 VERIFICAR SI USERNAME YA EXISTE
  /// ---------------------------
  /// Retorna true si el username ya está en uso por otro usuario
  /// [username] - El username a verificar
  /// [excludeUserId] - El ID del usuario actual (para excluirlo de la búsqueda al editar)
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      if (normalizedUsername.isEmpty || normalizedUsername.length < 3) {
        return false; // Username inválido, no buscar
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('✅ [UserService] Username "$normalizedUsername" disponible');
        return false;
      }

      // Si hay un resultado, verificar si es el mismo usuario (para edición)
      if (excludeUserId != null) {
        final existingUserId = querySnapshot.docs.first.id;
        if (existingUserId == excludeUserId) {
          debugPrint(
            '✅ [UserService] Username "$normalizedUsername" pertenece al mismo usuario',
          );
          return false; // El username pertenece al usuario actual, está OK
        }
      }

      debugPrint(
        '⚠️ [UserService] Username "$normalizedUsername" ya está en uso',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [UserService] Error verificando username: $e');
      return false; // En caso de error, permitir (la validación final será en el servidor)
    }
  }
}
