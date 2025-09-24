import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuaria actual
  User? getCurrentUser() => _auth.currentUser;

  // Future<UserCredential> signInLogin(String email, password) async {
  //   try {
  //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //       // verificar datos de usuario en la base de datos
  //       email: email,
  //       password: password,
  //     );

  //     // save user info if it doesn't already exist
  //     _firestore.collection("Users").doc(userCredential.user!.uid).set({
  //       'uid': userCredential.user!.uid,
  //       'email': email,
  //     });

  //     return userCredential;
  //   } on FirebaseAuthException catch (e) {
  //     throw Exception(e.code);
  //   }
  // }

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

  // Cambiar contraseña
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado');
    }

    try {
      // Actualizar la contraseña
      await user.updatePassword(newPassword);
      debugPrint('Contraseña actualizada correctamente');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Necesitas volver a iniciar sesión para cambiar la contraseña',
        );
      } else {
        throw Exception('Error al cambiar la contraseña: ${e.code}');
      }
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
