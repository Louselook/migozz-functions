import 'package:injectable/injectable.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/get_current_user_use_case.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/login_google_use_case.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/login_apple_use_case.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/login_use_case.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/register_use_case.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/signout_use_case.dart';
import 'package:migozz_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/features/profile/data/domain/repository/user_repository.dart';
import 'package:migozz_app/features/profile/data/domain/use_cases/change_avatar_use_case.dart';
import 'package:migozz_app/features/profile/data/domain/use_cases/update_user_profile_use_case.dart';
import 'package:migozz_app/features/profile/data/domain/use_cases/user_use_cases.dart';
import 'package:migozz_app/features/profile/data/repository/user_repository_impl.dart';

@module
abstract class AppModule {
  @injectable
  AuthService get authService => AuthService();

  @injectable
  AuthRepository get authRepository => AuthRepositoryImpl(authService);

  @injectable
  AuthUseCases get authUseCases => AuthUseCases(
    login: LoginUseCase(authRepository),
    register: RegisterUseCase(authRepository),
    loginGoogle: LoginGoogleUseCase(authRepository),
    loginApple: LoginAppleUseCase(authRepository),
    signout: SignOutUseCase(authRepository),
    getCurrentUser: GetCurrentUserUseCase(authRepository),
    authStateChanges: authRepository.authStateChanges(),
  );

  // location
  @lazySingleton
  LocationService get locationService => LocationService();

  @lazySingleton
  UserMediaService get userMediaService => UserMediaService();

  @lazySingleton
  UserService get userService => UserService(userMediaService);

  @lazySingleton
  UserRepository get userRepository => UserRepositoryImpl(userService);

  @lazySingleton
  UserUseCases get userUseCases => UserUseCases(
    changeAvatar: ChangeAvatarUseCase(userRepository),
    updateUserProfile: UpdateUserProfileUseCase(userRepository),
  );
}
