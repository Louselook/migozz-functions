import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';

enum UserDetailsAction { next, finalRegister, back }

Widget userDetailsButton({
  required PageController controller,
  required BuildContext context,
  UserDetailsAction action = UserDetailsAction.back,
  RegisterCubit? cubit,
  MoreUserDetailsMode mode = MoreUserDetailsMode.register,
  Future<void> Function()? onFinalAction,

  /// parámetro opcional
  bool? hasChanges,
}) {
  return GradientButton(
    width: double.infinity,
    radius: 19,
    onPressed: () async {
      switch (action) {
        case UserDetailsAction.next:
          controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          break;

        case UserDetailsAction.finalRegister:
          if (onFinalAction != null) {
            await onFinalAction();
          }
          break;

        case UserDetailsAction.back:
          //  MODIFICADO: Comportamiento diferente según el modo
          if (mode == MoreUserDetailsMode.register) {
            // Modo registro: limpiar y cerrar
            cubit?.setSocialEcosystemEmty();
            context.pop('done');
          } else {
            // Modo edición: solo navegar a la página anterior
            controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          break;
      }
    },
    child: SecondaryText(
      // Texto diferente según el modo y acción
      _getButtonText(action, mode, hasChanges),
      fontSize: 20,
    ),
  );
}

// Obtener texto del botón según el modo
String _getButtonText(
  UserDetailsAction action,
  MoreUserDetailsMode mode,
  bool? hasChanges,
) {
  // 🔹 Solo afecta en EDIT MODE
  if (mode == MoreUserDetailsMode.edit) {
    if (hasChanges == true) return "Save";
    return "Back"; // hasChanges false o null → Back
  }

  // 🔹 Modo registro → siempre Continue
  return "Continue";
}
