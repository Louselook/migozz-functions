import 'package:migozz_app/features/auth/data/domain/models/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

class LoginGoogleUseCase {
  final AuthRepository repository;

  LoginGoogleUseCase(this.repository);

  Future<AuthResult> run({bool createIfNotExists = false}) {
    return repository.loginWithGoogle();
  }
}
