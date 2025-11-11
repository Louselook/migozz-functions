// models/auth_result.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

class AuthResult {
  final UserCredential credential;
  final UserDTO? user;
  final bool profileExists;

  AuthResult({
    required this.credential,
    required this.user,
    required this.profileExists,
  });
}
