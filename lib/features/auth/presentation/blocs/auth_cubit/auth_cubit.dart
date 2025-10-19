import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/auth_result.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthUseCases _authUseCases;
  final UserMediaService _mediaService;
  late final StreamSubscription<User?> _authSub;

  AuthCubit(this._authUseCases, this._mediaService)
    : super(const AuthState.checking()) {
    // 🔔 Suscripción a cambios de sesión de Firebase
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
            final needsCompletion = _checkProfileIncomplete(userProfile);

            emit(
              AuthState.authenticated(
                firebaseUser: user,
                userProfile: userProfile,
                needsCompletion: needsCompletion,
              ),
            );

            if (needsCompletion) {
              debugPrint(
                '⚠️ [AuthCubit] Perfil incompleto → necesita completarse',
              );
            } else {
              debugPrint('✅ [AuthCubit] Perfil completo cargado correctamente');
            }
          } catch (e) {
            debugPrint('❌ [AuthCubit] Error cargando perfil: $e');
            emit(
              AuthState.authenticated(
                firebaseUser: user,
                userProfile: null,
                needsCompletion: true,
              ),
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

  // ==============================
  // 🔄 Cargar perfil con reintentos
  // ==============================
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

  // ==============================
  // 🧩 Verificar si el perfil está incompleto
  // ==============================
  bool _checkProfileIncomplete(UserDTO? profile) {
    if (profile == null) return true;

    final hasBasicInfo =
        profile.displayName.isNotEmpty &&
        profile.username.isNotEmpty &&
        profile.email.isNotEmpty;

    final hasLocation =
        profile.location.country.isNotEmpty &&
        profile.location.state.isNotEmpty &&
        profile.location.city.isNotEmpty;

    final hasGender = profile.gender.isNotEmpty;

    return !(hasBasicInfo && hasLocation && hasGender);
  }

  // ==============================
  // 🔐 Login con Google
  // ==============================
  Future<AuthResult> signInWithGoogle() async {
    try {
      return await _authUseCases.loginGoogle.run();
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en login con Google: $e');
      rethrow;
    }
  }

  // ==============================
  // 🔐 Login con email/OTP
  // ==============================
  Future<AuthResult> login({required String email, required String otp}) async {
    try {
      return await _authUseCases.login.run(email: email, otp: otp);
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en login: $e');
      rethrow;
    }
  }

  // ==============================
  // 🧾 Completar registro
  // ==============================
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
      await _mediaService.associateMediaToUid(uid: uid, email: email);

      return uid;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en registro: $e');
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // ==============================
  // 🔁 Refrescar perfil (ej. después de editar)
  // ==============================
  Future<void> refreshUserProfile() async {
    if (!state.isAuthenticated || state.firebaseUser == null) return;

    try {
      debugPrint('🔄 [AuthCubit] Refrescando perfil...');
      final userProfile = await _authUseCases.getCurrentUser.run();
      final needsCompletion = _checkProfileIncomplete(userProfile);

      emit(
        state.copyWith(
          userProfile: userProfile,
          needsCompletion: needsCompletion,
        ),
      );

      if (userProfile != null) {
        debugPrint('✅ [AuthCubit] Perfil actualizado');
      } else {
        debugPrint('⚠️ [AuthCubit] Perfil vacío al refrescar');
      }
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error refrescando perfil: $e');
    }
  }

  void setNeedsCompletion(bool value) {
    emit(state.copyWith(needsCompletion: value));
  }

  // ==============================
  // 🚪 Logout
  // ==============================
  Future<void> logout() async {
    await _authUseCases.signout.run();
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
