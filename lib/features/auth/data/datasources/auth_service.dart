import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserMediaService _mediaService = UserMediaService();

  // Stream de auth
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Helper para obtener UserDTO
  Future<UserDTO?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserDTO(
      email: data['email'] ?? '',
      lang: data['lang'] ?? 'es',
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      gender: data['gender'] ?? '',
      socialEcosystem: data['socialEcosystem'] != null
          ? List<Map<String, dynamic>>.from((data['socialEcosystem'] as List))
          : null,
      location: data['location'] != null
          ? LocationDTO.fromMap(Map<String, dynamic>.from(data['location']))
          : LocationDTO(country: '', state: '', city: '', lat: 0, lng: 0),
      avatarUrl: data['avatarUrl'],
      phone: data['phone'],
      voiceNoteUrl: data['voiceNoteUrl'],
      category: data['category'] != null
          ? List<String>.from(data['category'])
          : null,
      interests: data['interests'] != null
          ? Map<String, List<String>>.from(
              (data['interests'] as Map).map(
                (k, v) => MapEntry(k.toString(), List<String>.from(v ?? [])),
              ),
            )
          : <String, List<String>>{},
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Future<UserDTO?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserDTO.fromMap(Map<String, dynamic>.from(doc.data()!));
  }

  Future<bool> emailExists(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // LOGIN con Google
  Future<AuthResult> loginWithGoogle() async {
    try {
      // ✅ Detecta automáticamente si es web o no
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? null // Web usa el ID desde index.html
            : dotenv.env['GOOGLE_CLIENT_ID'], // <-- tu clientId tipo Web
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('cancelled_by_user');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('firebase_sign_in_failed');

      // 🔎 Verifica si el perfil ya existe
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      bool profileExists = doc.exists;

      // 🆕 Si el usuario no existía, creamos el documento base
      if (!profileExists) {
        final baseData = {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'avatarUrl': user.photoURL ?? '',
          'phone': user.phoneNumber ?? '',
          'username':
              '@${(user.displayName ?? 'user').replaceAll(' ', '').toLowerCase()}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'complete': false,
        };
        await docRef.set(baseData);
        profileExists = true;
      }

      final userDto = await _getUserFromFirestore(user.uid);

      return AuthResult(
        credential: userCredential,
        user: userDto,
        profileExists: profileExists,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en login con Google: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // LOGIN con email + OTP
  Future<AuthResult> login({required String email, required String otp}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: otp,
      );
      final uid = userCredential.user!.uid;
      final userDto = await _getUserFromFirestore(uid);
      return AuthResult(
        credential: userCredential,
        user: userDto,
        profileExists: userDto != null,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en login: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // REGISTER
  // REGISTER (FIXED)
  Future<AuthResult> register({
    required String email,
    required String otp,
    required UserDTO userData,
  }) async {
    try {
      debugPrint('🚀 [AuthService] Iniciando registro...');
      debugPrint('🚀 [AuthService] Email: $email');

      // 1️⃣ Crear usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: otp,
      );
      final uid = userCredential.user!.uid;
      debugPrint('✅ [AuthService] Usuario creado con UID: $uid');

      // 2️⃣ Guardar documento base
      final userToSave = userData.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.set(userToSave.toMap());
      debugPrint('✅ [AuthService] Documento base guardado en Firestore');

      // 3️⃣ Asociar archivos del correo → UID (SOLO UNA VEZ)
      Map<MediaType, String> associatedUrls = {};
      try {
        debugPrint('🔄 [AuthService] Iniciando asociación de archivos...');
        associatedUrls = await _mediaService.associateMediaToUid(
          uid: uid,
          email: email,
        );
        debugPrint(
          '✅ [AuthService] Archivos asociados: ${associatedUrls.keys}',
        );

        if (associatedUrls.isNotEmpty) {
          final updates = {
            if (associatedUrls.containsKey(MediaType.avatar))
              'avatarUrl': associatedUrls[MediaType.avatar],
            if (associatedUrls.containsKey(MediaType.voice))
              'voiceNoteUrl': associatedUrls[MediaType.voice],
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await docRef.update(updates);
          debugPrint(
            '✅ [AuthService] URLs actualizadas en Firestore: $updates',
          );
        } else {
          debugPrint('ℹ️ [AuthService] No hay archivos para asociar');
        }
      } catch (e) {
        debugPrint(
          '⚠️ [AuthService] Error al asociar archivos (no crítico): $e',
        );
        // No fallar el registro por esto
      }

      final savedDto = await _getUserFromFirestore(uid);
      debugPrint('✅ [AuthService] Registro completado exitosamente');

      return AuthResult(
        credential: userCredential,
        user: savedDto,
        profileExists: savedDto != null,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code}');
      throw Exception('Error en registro: ${e.code}');
    } catch (e) {
      debugPrint('❌ [AuthService] Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
