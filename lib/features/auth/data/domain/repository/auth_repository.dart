import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import '../models/user/auth_result.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<AuthResult> login({required String email, required String otp});

  Future<AuthResult> register({
    required String email,
    required String otp,
    required UserDTO userData,
  });

  /// Create Firebase Auth user ONLY (no Firestore document)
  /// Used for pre-registered users whose document will be migrated
  Future<String> createAuthUserOnly({
    required String email,
    required String password,
  });

  Future<AuthResult> loginWithGoogle();

  Future<AuthResult> loginWithApple();

  Future<void> signOut();

  Future<bool> emailExists(String email);

  Future<UserDTO?> getCurrentUser();
}
