import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

/// Valida la respuesta del usuario según el índice del bot
bool validateCurrentField({required int botIndex, String? userResponse}) {
  if (userResponse == null || userResponse.trim().isEmpty) return false;

  switch (botIndex) {
    case 9: // teléfono
      return RegExp(r"^\+?\d{7,15}$").hasMatch(userResponse);
    case 20: // email
      return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(userResponse);
    // case 8: // teléfono
    //   return RegExp(r"^\+?\d{7,15}$").hasMatch(userResponse);
    default:
      return true;
  }
}

/// Mapear automáticamente la respuesta al RegisterCubit
Future<void> mapResponseToCubit({
  required int botIndex,
  required String userResponse,
  required RegisterCubit cubit,
}) async {
  switch (botIndex) {
    // email
    case 1:
      cubit.setLanguage(userResponse);
      break;
    case 2:
      cubit.setFullName(userResponse);
      break;
    case 3:
      cubit.setUsername(userResponse);
      break;
    case 4:
      cubit.setGender(userResponse);
      break;
    // setSocialEcosystem
    case 7: // setLocation
      // cubit.setLocation(
      //   LocationDTO(
      //     country: "Colombia",
      //     state: "Antioquia",
      //     city: "Medellín",
      //     lat: 6.2442,
      //     lng: -75.5812,
      //   ),
      // );
      // // Confirmar con si la ubicacion
      // if (parseYesNo(userResponse)) {
      // } else {}
      break;
    case 8:
      // Confirmar con si para mandar el otp
      // if (parseYesNo(userResponse)) {
        final Map<String, dynamic> result = await sendOTP(
          email: cubit.state.email!,
        );
        if (result["sent"] == true) {
          cubit.setCurrentOTP(result["myOTP"]);
          debugPrint("Enviado");
        } else {
          // Manejar error de envío
          debugPrint("No se pudo enviar el OTP");
        }
      // } else {}
      break;
    case 9:
      // codigo OTP
      if (userResponse == cubit.state.currentOTP) {
        cubit.updateEmailVerification(EmailVerification.success);
        // Aquí podrías actualizar un estado de confirmación de email
      }
      break;
    case 13:
      // Avatar
      final file = File(userResponse); // userResponse = ruta local
      if (await file.exists()) {
        cubit.setAvatarFile(file);
      }
      break;
    case 14:
      cubit.setPhone(userResponse);
      // Intentar completar registro cuando ya hay teléfono
      await cubit.checkCompletion();
      break;
    case 15:
      // audio pude ser texto
      final vFile = File(userResponse);
      if (await vFile.exists()) {
        cubit.setVoiceNoteFile(vFile);
      }
      await cubit.checkCompletion();
      break;
    // setInterests
    default:
      break;
  }
}

bool parseYesNo(String userResponse) {
  final normalized = userResponse.trim().toLowerCase();

  const affirmative = ['si', 's', 'yes', 'y'];

  // Solo retorna true si es afirmativo, cualquier otra cosa es false
  return affirmative.contains(normalized);
}
