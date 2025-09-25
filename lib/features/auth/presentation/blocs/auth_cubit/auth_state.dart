import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;

  const AuthState._({required this.status, this.user});

  const AuthState.checking() : this._(status: AuthStatus.checking);
  const AuthState.authenticated(User user)
    : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.notAuthenticated()
    : this._(status: AuthStatus.notAuthenticated);
}
