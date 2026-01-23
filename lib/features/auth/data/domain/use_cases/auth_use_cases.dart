import 'package:firebase_auth/firebase_auth.dart';

import 'login_use_case.dart';
import 'login_google_use_case.dart';
import 'login_apple_use_case.dart';
import 'signout_use_case.dart';
import 'register_use_case.dart';
import 'get_current_user_use_case.dart';
import 'create_auth_user_use_case.dart';

class AuthUseCases {
  final LoginUseCase login;
  final RegisterUseCase register;
  final CreateAuthUserUseCase createAuthUser;
  final LoginGoogleUseCase loginGoogle;
  final LoginAppleUseCase loginApple;
  final SignOutUseCase signout;
  final GetCurrentUserUseCase getCurrentUser;
  final Stream<User?> authStateChanges;

  AuthUseCases({
    required this.login,
    required this.register,
    required this.createAuthUser,
    required this.loginGoogle,
    required this.loginApple,
    required this.signout,
    required this.getCurrentUser,
    required this.authStateChanges,
  });
}
