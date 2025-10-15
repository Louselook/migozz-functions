// auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';

class SocialSignInResult {
  final UserCredential credential;
  final bool profileExists;

  SocialSignInResult({required this.credential, required this.profileExists});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Escuchar cambios de autenticación en tiempo real
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Comprueba si existe un documento de usuario por email
  Future<bool> emailExists(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  /// Inicia sesión con Google y devuelve si existe perfil en Firestore.
  /// No crea documento automaticamente.
  Future<SocialSignInResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Usuario canceló el flujo
        throw Exception('cancelled_by_user');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(
        credential,
      ); // Firebase sign in

      final user = userCredential.user;
      if (user == null) {
        throw Exception('firebase_sign_in_failed');
      }

      // Revisa si existe documento en Firestore para este uid
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final profileExists = doc.exists;

      return SocialSignInResult(
        credential: userCredential,
        profileExists: profileExists,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<SocialSignInResult> signInWithGoogleCreateIfNotExists() async {
    try {
      final result = await signInWithGoogle();

      final user = result.credential.user;
      final uid = user?.uid;

      if (uid == null || user == null) {
        throw Exception('user_missing_after_signin');
      }

      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final baseData = <String, dynamic>{
          'uid': uid,
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'username':
              '@${(user.displayName ?? 'user').replaceAll(' ', '').toLowerCase()}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'socialEcosystem': [],
        };

        await docRef.set(baseData);
      }

      // 🔥 Esperar confirmación de que Firestore tiene el doc
      await Future.delayed(const Duration(milliseconds: 400));

      return SocialSignInResult(
        credential: result.credential,
        profileExists: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registra con email/otp (ya existente en tu archivo)
  Future<UserCredential> signInWithOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: otp,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en login: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado en login: $e');
    }
  }

  /// Sign up con userDTO (ya existente en tu archivo)
  Future<UserCredential> signUpRegister({
    required String email,
    required String otp,
    required UserDTO userData,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: otp);

      final uid = userCredential.user!.uid;

      final userToSave = userData.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userToSave.toMap());
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en registro: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// fetchUserSocialEcosystem (mantener tu implementación actual)
  Future<List<Map<String, Map<String, dynamic>>>> fetchUserSocialEcosystem({
    String? uid,
  }) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return [];

    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return [];

    final List<Map<String, Map<String, dynamic>>> result = [];

    if (data['socials'] != null && data['socials'] is Map) {
      final socialsMap = Map<String, dynamic>.from(data['socials']);
      socialsMap.forEach((key, value) {
        final lowerKey = key.toString().toLowerCase();
        if (value is Map) {
          result.add({lowerKey: Map<String, dynamic>.from(value)});
        } else {
          result.add({
            lowerKey: <String, dynamic>{'username': value},
          });
        }
      });
    }

    if (data['socialEcosystem'] != null && data['socialEcosystem'] is List) {
      final list = List.from(data['socialEcosystem']);
      for (final item in list) {
        try {
          final mapItem = Map<String, dynamic>.from(item);
          for (final key in mapItem.keys) {
            final lowerKey = key.toString().toLowerCase();
            final inner = mapItem[key];
            if (inner is Map) {
              result.add({lowerKey: Map<String, dynamic>.from(inner)});
            } else {
              result.add({
                lowerKey: <String, dynamic>{'value': inner},
              });
            }
          }
        } catch (_) {
          continue;
        }
      }
    }
    return result;
  }

  /// Cierra sesión (Auth + Google)
  Future<void> signOutHome() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
