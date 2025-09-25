import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Escuchar cambios de autenticación en tiempo real
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithOTP({
    required String email,
    required String otp,
  }) async {
    try {
      // acá otp se usa como "password"
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

  // sing up
  Future<UserCredential> signUpRegister({
    required String email,
    required String otp,
    required UserDTO userData,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: otp);

      final uid = userCredential.user!.uid;

      // Guardar en Firestore con createdAt y updatedAt actualizados
      final userToSave = userData.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // await _firestore.collection('users').doc(uid).set(userToSave.toMap());
      await _firestore.collection('test').doc(uid).set(userToSave.toMap());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en registro: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // sing out
  Future<void> signOutHome() async {
    return await _auth.signOut();
  }

  // errors
}
