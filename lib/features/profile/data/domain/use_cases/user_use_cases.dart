import 'change_avatar_use_case.dart';
import 'update_user_profile_use_case.dart';

class UserUseCases {
  final ChangeAvatarUseCase changeAvatar;
  final UpdateUserProfileUseCase updateUserProfile;

  UserUseCases({required this.changeAvatar, required this.updateUserProfile});
}
