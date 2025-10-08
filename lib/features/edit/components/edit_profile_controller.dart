import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/edit/components/user_profile.dart';

class EditProfileController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final _mediaService = UserMediaService();

  /// Carga el usuario actual desde Firestore
  Future<UserProfile?> loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserProfile.fromFirestore(user.uid, doc.data());
  }

  /// Guarda los cambios del perfil del usuario (merge para no sobreescribir)
  Future<UserProfile> saveUserProfile(UserProfile updated) async {
    await _firestore
        .collection('users')
        .doc(updated.id)
        .set(updated.toFirestore(), SetOptions(merge: true));

    return updated;
  }

  /// Cambia el avatar y actualiza su URL en Firestore
  Future<String?> changeAvatar(String userId, String email) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final urls = await _mediaService.uploadFilesTemporarily(
      email: email,
      files: {MediaType.avatar: File(picked.path)},
    );

    final newUrl = urls[MediaType.avatar];
    if (newUrl == null) return null;

    await _firestore.collection('users').doc(userId).set({
      'avatarUrl': newUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return newUrl;
  }
}
