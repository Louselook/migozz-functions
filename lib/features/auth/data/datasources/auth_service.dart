import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/auth/services/pre_register_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserMediaService _mediaService = UserMediaService();
  final PreRegisterService _preRegisterService = PreRegisterService();

  // Stream de auth
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Helper para obtener UserDTO
  Future<UserDTO?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserDTO.fromMap(Map<String, dynamic>.from(doc.data()!));
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
      final googleSignIn = GoogleSignIn.instance;

      // Inicializa: solo pasa clientId en web
      if (kIsWeb && dotenv.env['GOOGLE_CLIENT_ID'] != null) {
        await googleSignIn.initialize(clientId: dotenv.env['GOOGLE_CLIENT_ID']);
      } else {
        await googleSignIn.initialize();
      }

      // 1) UI de login
      final googleUser = await googleSignIn.authenticate();

      // 2) pedir autorización para scopes (devuelve accessToken si existe)
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes([
            'email',
            'profile',
            // 'openid' no garantiza idToken en todas las plataformas v7, pero no hace daño pedirlo.
            'openid',
          ]);

      if (authorization == null) throw Exception('authorization_failed');

      final String accessToken = authorization.accessToken;

      debugPrint('🔐 accessToken length: ${accessToken.length}');

      if (accessToken.isEmpty) {
        throw Exception('no_access_token_obtained');
      }

      // 3) crear credential SOLO con accessToken (idToken no está disponible en v7)
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        // idToken: null,
      );

      // 4) sign in en Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('firebase_sign_in_failed');

      // 5) Verificar si este email tiene un pre-order
      String? reservedUsername;
      if (user.email != null) {
        debugPrint(
          '🔍 [AuthService] Verificando pre-order para: ${user.email}',
        );
        final preOrderData = await _preRegisterService.getPreRegisterByEmail(
          user.email!,
        );

        if (preOrderData.isPreRegistered && preOrderData.preOrderId != null) {
          debugPrint(
            '📋 [AuthService] Pre-order encontrado: ${preOrderData.preOrderId}',
          );
          reservedUsername = preOrderData.username;

          // Eliminar el pre-order para evitar conflictos
          debugPrint('🗑️ [AuthService] Eliminando pre-order...');
          final deleted = await _preRegisterService.deletePreOrder(
            preOrderData.preOrderId!,
          );
          if (deleted) {
            debugPrint('✅ [AuthService] Pre-order eliminado exitosamente');
          } else {
            debugPrint('⚠️ [AuthService] No se pudo eliminar pre-order');
          }
        }
      }

      // 6) lógica Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      bool profileExists = doc.exists;

      if (!profileExists) {
        // Usar el username reservado del pre-order si existe, sino generar uno
        final username =
            reservedUsername ??
            (user.displayName ?? 'user').replaceAll(' ', '').toLowerCase();

        debugPrint(
          '📝 [AuthService] Creando documento con username: $username',
        );

        final baseData = {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'username': username,
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
      debugPrint('FirebaseAuthException code=${e.code} message=${e.message}');
      throw Exception('Error en login con Google: ${e.code}');
    } catch (e) {
      debugPrint('Error inesperado loginWithGoogle: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // LOGIN con Apple
  Future<AuthResult> loginWithApple() async {
    try {
      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('firebase_sign_in_failed');

      // Verificar si este email tiene un pre-order
      String? reservedUsername;
      final userEmail = user.email ?? appleCredential.email;
      if (userEmail != null) {
        debugPrint('🔍 [AuthService] Verificando pre-order para: $userEmail');
        final preOrderData = await _preRegisterService.getPreRegisterByEmail(
          userEmail,
        );

        if (preOrderData.isPreRegistered && preOrderData.preOrderId != null) {
          debugPrint(
            '📋 [AuthService] Pre-order encontrado: ${preOrderData.preOrderId}',
          );
          reservedUsername = preOrderData.username;

          // Eliminar el pre-order para evitar conflictos
          debugPrint('🗑️ [AuthService] Eliminando pre-order...');
          final deleted = await _preRegisterService.deletePreOrder(
            preOrderData.preOrderId!,
          );
          if (deleted) {
            debugPrint('✅ [AuthService] Pre-order eliminado exitosamente');
          } else {
            debugPrint('⚠️ [AuthService] No se pudo eliminar pre-order');
          }
        }
      }

      // Check if profile exists
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      bool profileExists = doc.exists;

      // If user doesn't exist, create base document
      if (!profileExists) {
        // Apple may provide name only on first sign-in
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty && appleCredential.givenName != null) {
          displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
        }

        // Usar el username reservado del pre-order si existe, sino generar uno
        final username =
            reservedUsername ??
            (displayName.isNotEmpty ? displayName : 'user')
                .replaceAll(' ', '')
                .toLowerCase();

        debugPrint(
          '📝 [AuthService] Creando documento con username: $username',
        );

        final baseData = {
          'displayName': displayName,
          'email': userEmail ?? '',
          'avatarUrl': user.photoURL ?? '',
          'phone': user.phoneNumber ?? '',
          'username': username,
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
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle user cancellation gracefully
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('cancelled_by_user');
      }
      throw Exception('Error en login con Apple: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en login con Apple: ${e.code}');
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

  /// Create Firebase Auth user ONLY (no Firestore document)
  /// Used for pre-registered users whose document will be migrated
  Future<String> createAuthUserOnly({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🚀 [AuthService] Creando usuario en Auth (solo Auth)...');
      debugPrint('🚀 [AuthService] Email: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      debugPrint('✅ [AuthService] Usuario Auth creado con UID: $uid');

      return uid;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code}');
      throw Exception('Error creando usuario Auth: ${e.code}');
    } catch (e) {
      debugPrint('❌ [AuthService] Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    // Note: Apple Sign-In doesn't require explicit sign out
    await _auth.signOut();
  }
}
