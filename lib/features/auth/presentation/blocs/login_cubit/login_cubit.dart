import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';
import 'package:migozz_app/pruebas/otp_validator.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit({required this.authService}) : super(const LoginState());

  /// Enviar OTP al email
  Future<void> sendOTPLoginCubit(String email) async {
    emit(state.copyWith(isLoading: true, email: email, errorMessage: null));

    try {
      final result = await sendOTP(email: email);

      if (result["sent"] == true) {
        debugPrint("✅ OTP enviado a $email: ${result["myOTP"]}");
        emit(state.copyWith(isLoading: false, currentOTP: result["myOTP"]));
      } else {
        emit(
          state.copyWith(isLoading: false, errorMessage: "Error al enviar OTP"),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Validar OTP y hacer login/registro
  Future<void> validateOTPAndLogin({required String inputOTP}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    if (inputOTP != state.currentOTP) {
      emit(state.copyWith(isLoading: false, errorMessage: "OTP incorrecto ❌"));
      return;
    }

    try {
      // 🚀 Paso 1: cambiar contraseña (y login automático en FirebaseAuth)
      final result = await changePassword(
        email: state.email!,
        newPassword: inputOTP, // si OTP será la clave temporal
      );

      if (!result.success) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: result.message ?? "Error al cambiar contraseña",
          ),
        );
        return;
      }

      // 🚀 Paso 2: Si todo OK, continuar con el flujo normal
      final userCredential = await authService.signInWithOTP(
        email: state.email!,
        otp: inputOTP,
      );

      if (userCredential.user != null) {
        // ✅ Usuario creado / logueado
        emit(state.copyWith(isLoading: false));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "No se pudo autenticar",
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Limpiar errores
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
