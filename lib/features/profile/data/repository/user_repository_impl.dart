import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/features/profile/data/domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserService service;

  UserRepositoryImpl(this.service);

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> fields) {
    return service.updateUserProfile(userId, fields);
  }

  @override
  Future<String?> changeAvatar(String userId) {
    return service.changeAvatar(userId);
  }
}
