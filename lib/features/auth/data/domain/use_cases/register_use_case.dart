import 'package:migozz_app/features/auth/data/domain/models/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthResult> run({
    required String email,
    required String otp,
    required UserDTO userData,
  }) {
    return repository.register(email: email, otp: otp, userData: userData);
  }
}
