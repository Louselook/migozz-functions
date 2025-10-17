import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'package:migozz_app/features/auth/services/otp_validator.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit({required this.authService}) : super(const LoginState());

  /// Enviar OTP al email
  Future<void> sendOTPLoginCubit(String email) async {
    // 🔹 Solo emitir si el estado realmente cambia
    if (!state.isLoading) {
      emit(
        state.copyWith(
          isLoading: true,
          email: email,
          errorMessageLogin: null,
          errorMessageOTP: null, // Limpiar errores OTP también
          loginSuccess: false, // Reset loginSuccess
        ),
      );
    }

    try {
      final result = await sendOTP(email: email);

      if (result["sent"] == true) {
        debugPrint("✅ OTP enviado a $email: ${result["myOTP"]}");

        // 🔹 Solo emitir si hay cambios reales
        emit(
          state.copyWith(
            isLoading: false,
            currentOTP: result["myOTP"],
            errorMessageLogin: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessageLogin: "Error al enviar OTP",
            currentOTP: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessageLogin: e.toString(),
          currentOTP: null,
        ),
      );
    }
  }

  Future<void> validateOTPAndLogin({required String inputOTP}) async {
    // 🔹 Evitar múltiples llamadas si ya está procesando
    if (state.isLoading) {
      debugPrint("⚠️ Ya se está procesando OTP, ignorando nueva llamada");
      return;
    }

    // 🔹 Evitar procesar si ya fue exitoso
    if (state.loginSuccess) {
      debugPrint("⚠️ Login ya fue exitoso, ignorando nueva llamada");
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        errorMessageOTP: null,
        errorMessageLogin: null,
        loginSuccess: false,
      ),
    );

    // 🔹 Delay mínimo para mostrar loading
    await Future.delayed(const Duration(milliseconds: 300));

    // 🔹 Validar OTP
    if (inputOTP != state.currentOTP) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessageOTP: "OTP incorrecto ❌",
          otpErrorCount: state.otpErrorCount + 1, // <-- incrementa contador
        ),
      );
      return;
    }

    try {
      // 🚀 Paso 1: cambiar contraseña
      final result = await changePassword(
        email: state.email!,
        newPassword: inputOTP,
      );

      if (!result.success) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessageOTP: result.message ?? "Error al cambiar contraseña",
            otpErrorCount: state.otpErrorCount + 1, // <-- incrementa contador
          ),
        );
        return;
      }

      // 🚀 Paso 2: login con OTP
      final userCredential = await authService.signInWithOTP(
        email: state.email!,
        otp: inputOTP,
      );

      if (userCredential.user != null) {
        // 🔹 Delay antes de marcar como exitoso
        await Future.delayed(const Duration(milliseconds: 200));

        // 🔹 Emitir estado de éxito FINAL
        emit(
          state.copyWith(
            isLoading: false,
            loginSuccess: true,
            errorMessageOTP: null,
            errorMessageLogin: null,
          ),
        );

        debugPrint("✅ Login exitoso para: ${state.email}");
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessageOTP: "No se pudo autenticar",
            otpErrorCount: state.otpErrorCount + 1, // <-- incrementa contador
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessageOTP: e.toString(),
          otpErrorCount: state.otpErrorCount + 1, // <-- incrementa contador
        ),
      );
    }
  }

  /// Reset completo del estado
  void resetState() {
    // 🔹 Solo resetear si no está ya en estado inicial
    if (state != const LoginState()) {
      emit(const LoginState());
      debugPrint("LoginCubit: estado reseteado ✅");
    }
  }

  /// Limpiar solo el éxito del login (útil para evitar navegaciones múltiples)
  void clearLoginSuccess() {
    emit(state.copyWith(loginSuccess: false));
    debugPrint("LoginCubit: loginSuccess limpiado");
  }
}
