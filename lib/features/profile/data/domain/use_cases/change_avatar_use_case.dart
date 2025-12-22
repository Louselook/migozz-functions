import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/data/domain/repository/user_repository.dart';

class ChangeAvatarUseCase {
  final UserRepository repository;

  ChangeAvatarUseCase(this.repository);

  Future<String?> run(String userId, BuildContext context) {
    return repository.changeAvatar(userId, context);
  }
}
