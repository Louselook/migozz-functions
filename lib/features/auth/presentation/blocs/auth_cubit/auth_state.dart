import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? firebaseUser;
  final UserDTO? userProfile;
  final bool isLoadingProfile;

  const AuthState({
    required this.status,
    this.firebaseUser,
    this.userProfile,
    this.isLoadingProfile = false,
  });

  // ===== Factories base =====
  const AuthState.checking()
    : status = AuthStatus.checking,
      firebaseUser = null,
      userProfile = null,
      isLoadingProfile = true;

  const AuthState.authenticated({required this.firebaseUser, this.userProfile})
    : status = AuthStatus.authenticated,
      isLoadingProfile = false;

  const AuthState.notAuthenticated()
    : status = AuthStatus.notAuthenticated,
      firebaseUser = null,
      userProfile = null,
      isLoadingProfile = false;

  // ===== copyWith =====
  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    UserDTO? userProfile,
    bool? isLoadingProfile,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: userProfile ?? this.userProfile,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
    );
  }

  // ===== Helpers =====
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isChecking => status == AuthStatus.checking;
  bool get isProfileComplete => userProfile != null && userProfile!.complete;

  @override
  List<Object?> get props => [
    status,
    firebaseUser?.uid,
    userProfile,
    isLoadingProfile,
  ];
}
