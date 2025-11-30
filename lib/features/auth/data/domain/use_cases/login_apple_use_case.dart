import 'package:migozz_app/features/auth/data/domain/models/user/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

class LoginAppleUseCase {
  final AuthRepository repository;

  LoginAppleUseCase(this.repository);

  Future<AuthResult> run() {
    return repository.loginWithApple();
  }
}

