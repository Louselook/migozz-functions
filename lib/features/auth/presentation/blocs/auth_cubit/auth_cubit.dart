import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthUseCases _authUseCases;
  final UserService _userService;
  late final StreamSubscription<User?> _authSub;
  StreamSubscription<DocumentSnapshot>? _userProfileSub; // ✅ Nuevo listener

  // ✅ Callback para limpiar otros cubits
  VoidCallback? onLogoutRequested;

  AuthCubit(this._authUseCases, this._userService)
    : super(const AuthState.checking()) {
    // ✅ Asegurar persistencia explícita en Web al inicializar el Cubit
    if (kIsWeb) {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    _authSub = _authUseCases.authStateChanges.listen(
      (user) async {
        debugPrint('🔔 [AuthCubit] authStateChanges: ${user?.uid ?? "null"}');

        if (user != null) {
          emit(
            state.copyWith(status: AuthStatus.checking, isLoadingProfile: true),
          );

          try {
            final userProfile = await _loadUserProfileWithRetry(user.uid);

            emit(
              AuthState.authenticated(
                firebaseUser: user,
                userProfile: userProfile,
              ),
            );

            // ✅ Iniciar listener de Firestore para el perfil del usuario
            _setupUserProfileListener(user.uid);

            if (userProfile == null || !userProfile.complete) {
              debugPrint(
                '⚠️ [AuthCubit] Perfil incompleto → necesita completarse',
              );
            } else {
              debugPrint('✅ [AuthCubit] Perfil completo cargado correctamente');
            }
          } catch (e) {
            debugPrint('❌ [AuthCubit] Error cargando perfil: $e');
            emit(
              AuthState.authenticated(firebaseUser: user, userProfile: null),
            );
          }
        } else {
          debugPrint('🔒 [AuthCubit] Usuario no autenticado');
          _cancelUserProfileListener(); // ✅ Cancelar listener si no hay usuario
          emit(const AuthState.notAuthenticated());
        }
      },
      onError: (err) {
        debugPrint('❌ [AuthCubit] authStateChanges error: $err');
        emit(const AuthState.notAuthenticated());
      },
    );
  }

  /// ✅ Configurar listener en tiempo real para el perfil del usuario
  void _setupUserProfileListener(String uid) {
    // Cancelar listener anterior si existe
    _cancelUserProfileListener();

    debugPrint('🔄 [AuthCubit] Configurando listener de perfil para UID: $uid');

    _userProfileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && state.isAuthenticated) {
              final data = snapshot.data();
              if (data != null) {
                final updatedProfile = UserDTO.fromMap(data);

                debugPrint('✨ [AuthCubit] Perfil actualizado en tiempo real');

                // Emitir nuevo estado con el perfil actualizado
                emit(
                  state.copyWith(
                    userProfile: updatedProfile,
                    isLoadingProfile: false,
                  ),
                );
              }
            }
          },
          onError: (error) {
            debugPrint('❌ [AuthCubit] Error en listener de perfil: $error');
          },
        );
  }

  /// ✅ Cancelar listener del perfil
  void _cancelUserProfileListener() {
    _userProfileSub?.cancel();
    _userProfileSub = null;
  }

  Future<UserDTO?> _loadUserProfileWithRetry(
    String uid, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final userProfile = await _authUseCases.getCurrentUser.run();
        if (userProfile != null) {
          return userProfile;
        }

        if (i < maxRetries - 1) {
          debugPrint(
            '🔄 [AuthCubit] Reintentando cargar perfil (${i + 1}/$maxRetries)',
          );
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (e) {
        debugPrint('❌ [AuthCubit] Error intento ${i + 1}: $e');
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }
    return null;
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔐 [AuthCubit] Iniciando login con Google...');
      final result = await _authUseCases.loginGoogle.run();
      debugPrint('✅ [AuthCubit] Login exitoso: ${result.user}');
      return result;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en login con Google: $e');
      debugPrint('❌ [AuthCubit] Tipo de error: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<AuthResult> signInWithApple() async {
    try {
      debugPrint('🍎 [AuthCubit] Iniciando login con Apple...');
      final result = await _authUseCases.loginApple.run();
      debugPrint('✅ [AuthCubit] Login exitoso: ${result.user}');
      return result;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en login con Apple: $e');
      debugPrint('❌ [AuthCubit] Tipo de error: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<AuthResult> login({required String email, required String otp}) async {
    try {
      return await _authUseCases.login.run(email: email, otp: otp);
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en login: $e');
      rethrow;
    }
  }

  Future<String> completeRegistration({
    required String email,
    required String otp,
    required UserDTO userData,
  }) async {
    try {
      final result = await _authUseCases.register.run(
        email: email,
        otp: otp,
        userData: userData,
      );

      if (result.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado después del registro');
      }

      final uid = currentUser.uid;
      debugPrint('✅ [AuthCubit] Registro completado para UID: $uid');
      return uid;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en registro: $e');
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Create Firebase Auth user ONLY (no Firestore document)
  /// Used for pre-registered users whose document will be migrated
  Future<String> createAuthUserOnly({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🚀 [AuthCubit] Creando usuario Auth (solo Auth)...');
      final uid = await _authUseCases.createAuthUser.run(
        email: email,
        password: password,
      );
      debugPrint('✅ [AuthCubit] Usuario Auth creado con UID: $uid');
      return uid;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error creando usuario Auth: $e');
      throw Exception('Error al crear usuario Auth: $e');
    }
  }

  /// ✅ Ahora es opcional - el listener se encarga automáticamente
  Future<void> refreshUserProfile() async {
    if (!state.isAuthenticated || state.firebaseUser == null) return;

    try {
      debugPrint('🔄 [AuthCubit] Refrescando perfil manualmente...');
      final userProfile = await _authUseCases.getCurrentUser.run();

      emit(state.copyWith(userProfile: userProfile, isLoadingProfile: false));

      if (userProfile != null && userProfile.complete) {
        debugPrint('✅ [AuthCubit] Perfil actualizado manualmente');
      } else {
        debugPrint('⚠️ [AuthCubit] Perfil vacío o incompleto al refrescar');
      }
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error refrescando perfil: $e');
    }
  }

  void markProfileTemporarilyComplete(bool value) {
    final currentProfile = state.userProfile;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(complete: value);
    emit(
      state.copyWith(
        userProfile: updatedProfile,
        isLoadingProfile: false,
        hasSeenCompleteProfileDialog: true,
      ),
    );
    debugPrint(
      '✅ [AuthCubit] Perfil marcado como temporalmente completo - dialogo no se mostrará en esta sesión',
    );
  }

  Future<void> updateProfileVersion(int version) async {
    if (!state.isAuthenticated ||
        state.firebaseUser == null ||
        state.userProfile == null) {
      throw Exception('Usuario no autenticado');
    }

    if (version < 1 || version > 3) {
      throw Exception('Versión inválida. Debe ser 1, 2 o 3');
    }

    try {
      final uid = state.firebaseUser!.uid;
      debugPrint(
        '🔄 [AuthCubit] Actualizando versión de perfil a: $version para UID: $uid',
      );

      await _userService.updateUserProfile(uid, {'profileVersion': version});

      // ✅ Ya no es necesario actualizar manualmente - el listener lo hará
      debugPrint(
        '✅ [AuthCubit] Versión de perfil actualizada - listener actualizará el estado',
      );
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error actualizando versión de perfil: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('🚪 [AuthCubit] Iniciando logout...');

    _cancelUserProfileListener();

    // ✅ Notificar a otros cubits para que se limpien
    if (onLogoutRequested != null) {
      debugPrint('🧹 [AuthCubit] Limpiando otros cubits...');
      onLogoutRequested!();
    }

    await _authUseCases.signout.run();

    debugPrint('✅ [AuthCubit] Logout completado');
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    _cancelUserProfileListener(); // ✅ Limpiar al cerrar el cubit
    return super.close();
  }
}
