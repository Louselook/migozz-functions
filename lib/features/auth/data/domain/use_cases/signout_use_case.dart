import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<void> run() {
    return repository.signOut();
  }
}
