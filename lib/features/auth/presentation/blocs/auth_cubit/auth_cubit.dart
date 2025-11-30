import 'dart:async';
import 'package:flutter/material.dart';
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

  AuthCubit(this._authUseCases, this._userService)
    : super(const AuthState.checking()) {
    // 🔔 Volver al listener original (sin flag)
    _authSub = _authUseCases.authStateChanges.listen(
      (user) async {
        debugPrint('🔔 [AuthCubit] authStateChanges: ${user?.uid ?? "null"}');

        if (user != null) {
          // Mostrar pantalla de carga mientras se obtiene el perfil
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
          emit(const AuthState.notAuthenticated());
        }
      },
      onError: (err) {
        debugPrint('❌ [AuthCubit] authStateChanges error: $err');
        emit(const AuthState.notAuthenticated());
      },
    );
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

  // ✅ Registro sin flag - original
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

  Future<void> refreshUserProfile() async {
    if (!state.isAuthenticated || state.firebaseUser == null) return;

    try {
      debugPrint('🔄 [AuthCubit] Refrescando perfil...');
      final userProfile = await _authUseCases.getCurrentUser.run();

      emit(state.copyWith(userProfile: userProfile, isLoadingProfile: false));

      if (userProfile != null && userProfile.complete) {
        debugPrint('✅ [AuthCubit] Perfil actualizado y completo');
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
    emit(state.copyWith(userProfile: updatedProfile, isLoadingProfile: false));
  }

  /// Actualiza la versión de perfil preferida del usuario
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

      // Actualizar en Firebase usando UserService con el UID correcto
      await _userService.updateUserProfile(
        uid, // ← Usar UID en lugar de email
        {'profileVersion': version},
      );

      // Actualizar estado local
      final updatedProfile = state.userProfile!.copyWith(
        profileVersion: version,
        updatedAt: DateTime.now(),
      );

      emit(state.copyWith(userProfile: updatedProfile));

      debugPrint(
        '✅ [AuthCubit] Versión de perfil actualizada exitosamente en Firebase',
      );
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error actualizando versión de perfil: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authUseCases.signout.run();
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
