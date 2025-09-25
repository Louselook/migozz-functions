import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';

void doneChat(BuildContext context, RegisterCubit cubit) async {
  try {
    // datos para pruebas
    final filledState = cubit.state.copyWith(
      avatarUrl: "https://picsum.photos/200",
      phone: "+57 3001234567",
      voiceNoteUrl: "https://storage.fake/voice123.mp3",
      category: "technology",
      interests: {
        "music": ["rock", "pop"],
        "sports": ["fútbol", "ciclismo"],
      },
    );
    debugPrint(" Usuario final (mockeado): $filledState");
    final testUser = filledState.buildUserDTO();

    /// Toda eesta logica pasarla al cubit
    // datos reales
    // final testUser = cubit.state.buildUserDTO();

    final authService = AuthService();

    final userCredential = await authService.signUpRegister(
      email: cubit.state.email!,
      otp: "123456", // contraseña temporal o el OTP que uses
      userData: testUser,
    );

    debugPrint(" Usuario creado en Firebase: ${userCredential.user?.uid}");

    //  Mostrar snackbar de éxito
    CustomSnackbar.show(
      // ignore: use_build_context_synchronously
      context: context,
      message: "Registro completado con éxito ",
      type: SnackbarType.success,
    );
  } catch (e) {
    debugPrint(" Error al registrar: $e");

    //  Mostrar snackbar de error
    CustomSnackbar.show(
      // ignore: use_build_context_synchronously
      context: context,
      message: "Error al registrar: $e",
      type: SnackbarType.error,
    );
  }
}
