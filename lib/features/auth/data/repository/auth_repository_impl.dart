import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;

  AuthRepositoryImpl(this.authService);

  @override
  Stream<User?> authStateChanges() => authService.authStateChanges();

  @override
  Future<AuthResult> login({required String email, required String otp}) {
    return authService.login(email: email, otp: otp);
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String otp,
    required UserDTO userData,
  }) {
    return authService.register(email: email, otp: otp, userData: userData);
  }

  @override
  Future<AuthResult> loginWithGoogle() {
    return authService.loginWithGoogle();
  }

  @override
  Future<AuthResult> loginWithApple() {
    return authService.loginWithApple();
  }

  @override
  Future<void> signOut() => authService.signOut();

  @override
  Future<bool> emailExists(String email) => authService.emailExists(email);

  @override
  Future<UserDTO?> getCurrentUser() => authService.getCurrentUser();
}
