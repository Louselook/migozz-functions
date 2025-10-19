import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? firebaseUser;
  final UserDTO? userProfile;
  final bool isLoadingProfile;
  final bool needsCompletion;

  const AuthState({
    required this.status,
    this.firebaseUser,
    this.userProfile,
    this.isLoadingProfile = false,
    this.needsCompletion = false,
  });

  // ===== Factories base =====
  const AuthState.checking()
    : status = AuthStatus.checking,
      firebaseUser = null,
      userProfile = null,
      isLoadingProfile = true,
      needsCompletion = false;

  const AuthState.authenticated({
    required this.firebaseUser,
    this.userProfile,
    this.needsCompletion = false,
  }) : status = AuthStatus.authenticated,
       isLoadingProfile = false;

  const AuthState.notAuthenticated()
    : status = AuthStatus.notAuthenticated,
      firebaseUser = null,
      userProfile = null,
      isLoadingProfile = false,
      needsCompletion = false;

  // ===== copyWith =====
  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    UserDTO? userProfile,
    bool? isLoadingProfile,
    bool? needsCompletion,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: userProfile ?? this.userProfile,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      needsCompletion: needsCompletion ?? this.needsCompletion,
    );
  }

  // ===== Helpers =====
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isChecking => status == AuthStatus.checking;
  bool get isProfileComplete => userProfile != null && !needsCompletion;

  @override
  List<Object?> get props => [
    status,
    firebaseUser?.uid,
    userProfile,
    isLoadingProfile,
    needsCompletion,
  ];
}
