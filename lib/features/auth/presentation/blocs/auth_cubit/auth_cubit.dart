// features/auth/presentation/blocs/auth_cubit/auth_cubit.dart
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
    // Suscribirse al stream que viene de AuthUseCases
    _authSub = _authUseCases.authStateChanges.listen(
      (user) async {
        debugPrint(
          '🔔 [AuthCubit] authStateChanges emitted user: ${user?.uid}',
        );
        if (user != null) {
          // Mientras cargamos el perfil dejamos isLoadingProfile = true
          emit(
            state.copyWith(status: AuthStatus.checking, isLoadingProfile: true),
          );
          try {
            final userProfile = await _authUseCases.getCurrentUser.run();
            emit(
              AuthState.authenticated(
                firebaseUser: user,
                userProfile: userProfile,
              ),
            );
            debugPrint('✅ [AuthCubit] Perfil cargado: ${userProfile?.email}');
          } catch (e) {
            debugPrint('❌ [AuthCubit] Error cargando perfil: $e');
            // Aunque falle la carga, emitimos authenticated con firebaseUser para seguir el flujo
            emit(AuthState.authenticated(firebaseUser: user));
          }
        } else {
          debugPrint('🔒 [AuthCubit] No hay usuario autenticado');
          emit(const AuthState.notAuthenticated());
        }
      },
      onError: (err) {
        debugPrint('❌ [AuthCubit] authStateChanges error: $err');
        emit(const AuthState.notAuthenticated());
      },
    );
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final result = await _authUseCases.loginGoogle.run();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResult> login({required String email, required String otp}) async {
    try {
      return await _authUseCases.login.run(email: email, otp: otp);
    } catch (e) {
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
        throw Exception('Error: No se pudo crear el usuario');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Error: Usuario no autenticado después del registro');
      }

      final uid = currentUser.uid;
      await _mediaService.associateMediaToUid(uid: uid, email: email);
      return uid;
    } catch (e) {
      debugPrint('❌ [AuthCubit] Error en registro: $e');
      throw Exception('Error al registrar usuario: $e');
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


  // /// Actualizar perfil del usuario
  // Future<void> updateUserProfile(UserDTO updatedProfile) async {
  //   if (state.firebaseUser == null) {
  //     throw Exception('No hay usuario autenticado');
  //   }

  //   try {
  //     // Aquí podrías tener un UpdateUserUseCase, pero por simplicidad:
  //     final uid = state.firebaseUser!.uid;

  //     // Usar Firestore directamente para actualización
  //     // O crear un UpdateUserUseCase si prefieres mantener la arquitectura completa
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid)
  //         .update(updatedProfile.copyWith(updatedAt: DateTime.now()).toMap());

  //     await reloadUserProfile();
  //   } catch (e) {
  //     throw Exception('Error actualizando perfil: $e');
  //   }
  // }

  // @override
  // Future<void> close() {
  //   _authSub.cancel();
  //   return super.close();
  // }
