import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';
// import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Escuchar cambios de autenticación en tiempo real
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> emailExists(String email) async {
    final querySnapshot = await firestore
        .collection('users') // nombre de tu colección
        .where('email', isEqualTo: email)
        .limit(1) // solo necesitamos verificar si hay al menos uno
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

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

      await _firestore.collection('users').doc(uid).set(userToSave.toMap());
      // await _firestore.collection('test').doc(uid).set(userToSave.toMap());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error en registro: ${e.code}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Set<String> extractSocialKeys(List<Map<String, Map<String, dynamic>>> platforms) {
  //   return platforms.map((m) => m.keys.first.toLowerCase()).toSet();
  // }

  /// Guarda un perfil social de un usuario en Firestore
  Future<List<Map<String, Map<String, dynamic>>>> fetchUserSocialEcosystem({
    String? uid,
  }) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return [];

    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return [];

    final List<Map<String, Map<String, dynamic>>> result = [];

    // 1) Legacy 'socials' (map)
    if (data['socials'] != null && data['socials'] is Map) {
      final socialsMap = Map<String, dynamic>.from(data['socials']);
      socialsMap.forEach((key, value) {
        final lowerKey = key.toString().toLowerCase();
        if (value is Map) {
          result.add({lowerKey: Map<String, dynamic>.from(value)});
        } else {
          // si en el legacy guardabas solo el handle (String), lo normalizamos
          result.add({lowerKey: <String, dynamic>{'username': value}});
        }
      });
    }

    // 2) Nuevo 'socialEcosystem' (lista de mapas)
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
              // si por alguna razón el value no es map
              result.add({lowerKey: <String, dynamic>{'value': inner}});
            }
          }
        } catch (_) {
          // ignora items mal formados
          continue;
        }
      }
    }

    return result;
  }

  // sing out
  Future<void> signOutHome() async {
    return await _auth.signOut();
  }

  // errors
}
