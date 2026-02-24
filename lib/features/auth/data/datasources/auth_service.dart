import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  /// En web con google_sign_in v7, authenticate() no está soportado.
  /// El sign-in se maneja via renderButton() + authenticationEvents.
  /// Este campo almacena el GoogleSignInAccount del evento para usarlo
  /// en loginWithGoogle() sin llamar authenticate() de nuevo.
  static GoogleSignInAccount? _pendingGoogleAccount;

  /// Llamar desde el listener de authenticationEvents en web
  /// antes de invocar loginWithGoogle().
  static void setPendingGoogleAccount(GoogleSignInAccount account) {
    _pendingGoogleAccount = account;
  }

  // Stream de auth
  Stream<User?> authStateChanges() {
    // Asegurar persistencia LOCAL habilitada en Web
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
    return _auth.authStateChanges();
  }

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

  /// ✅ Verifica si un email está asociado a una cuenta baneada
  /// Retorna: null si no existe o está activa, 'banned' si está baneada
  Future<String?> checkEmailBanned(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final data = querySnapshot.docs.first.data();
    final isActive = data['active'];

    // Si active es false o 0, la cuenta está baneada
    if (isActive == false || isActive == 0) {
      return 'banned';
    }

    return null;
  }

  /// ✅ Verifica si un username está asociado a una cuenta baneada
  /// Retorna: null si no existe o está activa, 'banned' si está baneada
  Future<String?> checkUsernameBanned(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final data = querySnapshot.docs.first.data();
    final isActive = data['active'];

    // Si active es false o 0, la cuenta está baneada
    if (isActive == false || isActive == 0) {
      return 'banned';
    }

    return null;
  }

  // LOGIN con Google
  Future<AuthResult> loginWithGoogle() async {
    try {
      debugPrint('🔐 [AuthService] Iniciando Google Sign-In...');

      // En v7, se debe inicializar con serverClientId en Android
      if (!kIsWeb) {
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '895592952324-4iu9ob4bo0ppn2hta6oi4qvfat3892p5.apps.googleusercontent.com',
        );
      }

      // En v7, authenticate() inicia el flujo interactivo en mobile.
      // En web, authenticate() NO está soportado — el sign-in viene de
      // renderButton() y llega via authenticationEvents. Usamos el account
      // almacenado en _pendingGoogleAccount.
      final GoogleSignInAccount googleUser;
      try {
        if (kIsWeb) {
          final pending = _pendingGoogleAccount;
          _pendingGoogleAccount = null; // Limpiar después de usar
          if (pending != null) {
            debugPrint('🔐 [AuthService] Web: usando cuenta de renderButton/GSI');
            googleUser = pending;
          } else if (GoogleSignIn.instance.supportsAuthenticate()) {
            debugPrint('🔐 [AuthService] Web: intentando authenticate()...');
            googleUser = await GoogleSignIn.instance.authenticate();
          } else {
            debugPrint('⚠️ [AuthService] Web: authenticate() no soportado y no hay cuenta pendiente');
            throw Exception('google_signin_cancelled');
          }
        } else {
          // Mobile: authenticate() inicia el flujo interactivo
          googleUser = await GoogleSignIn.instance.authenticate();
        }
      } catch (e) {
        debugPrint(
          '⚠️ [AuthService] Error o cancelación en Google Sign-In: $e',
        );
        // Si el usuario cancela, suele lanzar una excepción
        throw Exception('google_signin_cancelled');
      }

      debugPrint('✅ [AuthService] Usuario autenticado: ${googleUser.email}');

      // Obtener los tokens de autenticación (idToken)
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      debugPrint('🔐 [AuthService] Tokens obtenidos');

      // Crear credencial para Firebase
      // Nota: en v7, GoogleSignInAuthentication ya no tiene accessToken.
      // Firebase acepta idToken sin accessToken.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      debugPrint(
        '🔐 [AuthService] Credential creado, iniciando sesión en Firebase...',
      );

      // Sign in en Firebase
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
        debugPrint(
          '📝 [AuthService] isPreRegistered: ${reservedUsername != null}',
        );

        final baseData = {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'complete': false,
          'isPreRegistered':
              reservedUsername != null, // Marcar si viene de pre-order
          'active': true, // ✅ Usuario activo por defecto
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
        debugPrint(
          '📝 [AuthService] isPreRegistered: ${reservedUsername != null}',
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
          'isPreRegistered':
              reservedUsername != null, // Marcar si viene de pre-order
          'active': true, // ✅ Usuario activo por defecto
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
      debugPrint('🔐 [AuthService] Llamando createUserWithEmailAndPassword...');
      debugPrint('🔐 [AuthService] Password (OTP): $otp');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: otp,
      );

      final user = userCredential.user;
      if (user == null) {
        debugPrint('❌ [AuthService] ERROR: userCredential.user es NULL');
        throw Exception('Firebase no devolvió un usuario válido');
      }

      final uid = user.uid;
      debugPrint('✅ [AuthService] Usuario creado con UID: $uid');
      debugPrint('✅ [AuthService] Email verificado: ${user.email}');
      debugPrint('✅ [AuthService] Email del user: ${user.email}');
      debugPrint('✅ [AuthService] isAnonymous: ${user.isAnonymous}');
      debugPrint(
        '✅ [AuthService] Provider: ${user.providerData.map((p) => p.providerId).toList()}',
      );

      // Verificar que el usuario sigue autenticado (sin reload para evitar sign-out)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint(
          '❌ [AuthService] ERROR: currentUser es NULL después de crear',
        );
        throw Exception('Usuario desapareció después de crearlo');
      }
      debugPrint('✅ [AuthService] currentUser confirmado: ${currentUser.uid}');

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
