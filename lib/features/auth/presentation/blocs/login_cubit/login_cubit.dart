import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/services/otp_validator.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  /// Enviar OTP al email (solo UI/UX, no autenticación)
  /// [language] - Language code ('en' or 'es') for email content
  Future<void> sendOTPLoginCubit(
    String email, {
    String? forcedOTP,
    String language = 'en',
  }) async {
    if (!state.isLoading) {
      emit(
        state.copyWith(
          isLoading: true,
          email: email,
          errorMessageLogin: null,
          errorMessageOTP: null,
          loginSuccess: false,
        ),
      );
    }

    try {
      // Si nos pasan forcedOTP (modo test), lo usamos directamente
      if (forcedOTP != null) {
        // Simular pequeña espera para UX/consistencia
        await Future.delayed(const Duration(milliseconds: 250));
        debugPrint("✅ Forced OTP asignado a $email: $forcedOTP");

        emit(
          state.copyWith(
            isLoading: false,
            currentOTP: forcedOTP,
            errorMessageLogin: null,
          ),
        );
        return;
      }

      // Flujo real: llamar al servicio que envía OTP
      final result = await sendOTP(email: email, language: language);

      if (result["sent"] == true) {
        debugPrint("✅ OTP enviado a $email: ${result["myOTP"]}");

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
            errorMessageLogin: "login.otp.errorSend".tr(),
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

  /// Validar OTP (solo validación de UI, la autenticación real la hace AuthCubit)
  Future<bool> validateOTP({required String inputOTP}) async {
    if (state.isLoading) {
      debugPrint("⚠️ Ya se está procesando OTP, ignorando nueva llamada");
      return false;
    }

    if (state.loginSuccess) {
      debugPrint("⚠️ Login ya fue exitoso, ignorando nueva llamada");
      return false;
    }

    emit(
      state.copyWith(
        isLoading: true,
        errorMessageOTP: null,
        errorMessageLogin: null,
        loginSuccess: false,
      ),
    );

    // Delay mínimo para mostrar loading
    await Future.delayed(const Duration(milliseconds: 300));

    // Validar OTP localmente
    if (inputOTP != state.currentOTP) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessageOTP: "login.otp.errorInvalid".tr(),
          otpErrorCount: state.otpErrorCount + 1,
        ),
      );
      return false;
    }

    try {
      // Cambiar contraseña (preparación para el login real)
      final result = await changePassword(
        email: state.email!,
        newPassword: inputOTP,
      );

      if (!result.success) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessageOTP: result.message ?? "login.otp.errorPassword".tr(),
            otpErrorCount: state.otpErrorCount + 1,
          ),
        );
        return false;
      }

      // OTP válido, preparado para autenticación real
      emit(
        state.copyWith(
          isLoading: false,
          loginSuccess: true,
          errorMessageOTP: null,
          errorMessageLogin: null,
        ),
      );

      debugPrint("✅ OTP validado correctamente para: ${state.email}");
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessageOTP: e.toString(),
          otpErrorCount: state.otpErrorCount + 1,
        ),
      );
      return false;
    }
  }

  /// Reset completo del estado
  void resetState() {
    if (state != const LoginState()) {
      emit(const LoginState());
      debugPrint("LoginCubit: estado reseteado ✅");
    }
  }

  /// Limpiar solo el éxito del login
  void clearLoginSuccess() {
    emit(state.copyWith(loginSuccess: false));
    debugPrint("LoginCubit: loginSuccess limpiado");
  }

  /// Marcar error en la autenticación real (llamado desde la UI si AuthCubit falla)
  void setAuthenticationError(String error) {
    emit(
      state.copyWith(
        isLoading: false,
        errorMessageOTP: error,
        loginSuccess: false,
      ),
    );
  }
}
