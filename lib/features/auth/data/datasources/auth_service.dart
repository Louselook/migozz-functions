// auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:migozz_app/features/auth/data/domain/models/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';

class SocialSignInResult {
  // ya no lo usaremos externamente si usamos AuthResult; lo dejo por compatibilidad si quieres.
  final UserCredential credential;
  final bool profileExists;
  SocialSignInResult({required this.credential, required this.profileExists});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de auth
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Helper: obtener UserDTO desde Firestore
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

  // Exponer getCurrentUser que devuelve UserDTO?
  Future<UserDTO?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
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

  // LOGIN with Google -> devuelve AuthResult
  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
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

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      bool profileExists = doc.exists;

      if (!profileExists) {
        final baseData = <String, dynamic>{
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
        await Future.delayed(const Duration(milliseconds: 400));
        profileExists = true;
      }

      final userDto = await _getUserFromFirestore(user.uid);
      return AuthResult(
        credential: userCredential,
        user: userDto,
        profileExists: profileExists,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN email+otp -> devuelve AuthResult
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
      throw Exception('Error inesperado en login: $e');
    }
  }

  // REGISTER -> devuelve AuthResult (crea documento y retorna UserDTO)
  Future<AuthResult> register({
    required String email,
    required String otp,
    required UserDTO userData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: otp,
      );
      final uid = userCredential.user!.uid;

      final userToSave = userData.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(userToSave.toMap());

      final savedDto = await _getUserFromFirestore(uid);
      return AuthResult(
        credential: userCredential,
        user: savedDto,
        profileExists: savedDto != null,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en registro: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
