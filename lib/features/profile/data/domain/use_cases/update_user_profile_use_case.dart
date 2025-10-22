import 'package:migozz_app/features/profile/data/domain/repository/user_repository.dart';

class UpdateUserProfileUseCase {
  final UserRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<void> run(String userId, Map<String, dynamic> fields) {
    return repository.updateUserProfile(userId, fields);
  }
}
