import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';

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

  // Factory constructors para estados específicos
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

  // copyWith para actualizaciones parciales
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

  // Helper para saber si el perfil está completo
  bool get isProfileComplete => userProfile != null;

  // Helper para saber si está autenticado
  bool get isAuthenticated => status == AuthStatus.authenticated;

  // Helper para saber si está cargando
  bool get isChecking => status == AuthStatus.checking;

  @override
  List<Object?> get props => [
    status,
    firebaseUser?.uid,
    userProfile,
    isLoadingProfile,
  ];
}
