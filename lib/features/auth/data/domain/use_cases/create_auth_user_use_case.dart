import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

/// Use case for creating Firebase Auth user only (no Firestore document)
/// Used for pre-registered users whose document will be migrated
class CreateAuthUserUseCase {
  final AuthRepository repository;

  CreateAuthUserUseCase(this.repository);

  Future<String> run({required String email, required String password}) {
    return repository.createAuthUserOnly(email: email, password: password);
  }
}
