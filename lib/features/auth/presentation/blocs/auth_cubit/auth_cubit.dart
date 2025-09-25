import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  late final StreamSubscription<User?> _authSub;

  AuthCubit(this._authService) : super(AuthState.checking()) {
    // Suscripción en tiempo real a FirebaseAuth
    _authSub = _authService.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(AuthState.notAuthenticated());
      }
    });
  }

  Future<void> logout() async {
    await _authService.signOutHome();
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
