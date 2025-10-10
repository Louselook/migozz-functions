import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

Future<void> processBotResponse(
  Map<String, dynamic> resp, {
  required RegisterCubit registerCubit,
}) async {
  final String stepRaw = (resp['step'] ?? '').toString().toLowerCase();
  final RegisterStatusProgress step = _parseStep(stepRaw);

  final bool? isValid = resp['valid'];
  final String? userResponse = resp['userResponse'];
  final String? text = resp['text'];

  debugPrint('📩 [processBotResponse]');
  debugPrint('   • stepRaw: "$stepRaw"');
  debugPrint('   • step: $step');
  debugPrint('   • valid: $isValid');
  debugPrint('   • userResponse: $userResponse');
  debugPrint('   • text: $text');
  debugPrint('----------------------------------------');
  debugPrint('Estado de las variables: ${registerCubit.state}');

  switch (step) {
    case RegisterStatusProgress.language:
      // Validado
      if (isValid == true) {
        registerCubit.setLanguage(userResponse!);
      } else if (isValid == false) {
        debugPrint('⚠️ Respuesta inválida, se esperaba un idioma.');
      }
      break;

    case RegisterStatusProgress.fullName:
      debugPrint('🔹 Estás en el paso: fullName');
      if (isValid == true) {
        registerCubit.setFullName(userResponse!);
      } else if (isValid == false) {
        debugPrint('⚠️ Respuesta inválida, para fullName.');
      }
      break;

    case RegisterStatusProgress.username:
      debugPrint('✅ Registro completo (username)');
      registerCubit.setUsername(userResponse!);
      break;

    case RegisterStatusProgress.gender:
      debugPrint('✅ Registro completo (gender)');
      registerCubit.setGender(userResponse!);
      break;

    case RegisterStatusProgress.socialEcosystem:
      debugPrint('Abrir action: 0');
      break;

    case RegisterStatusProgress.location:
      debugPrint('✅ veerificar si o no (location)');
      registerCubit.setVerifyLocation();
      break;

    case RegisterStatusProgress.sendOTP:
      debugPrint('Puede que cambie de telefo\nemailVerification');
      if (registerCubit.state.email != null) {
        try {
          final result = await sendOTP(email: registerCubit.state.email!);
          if (result['sent'] == true) {
            registerCubit.setCurrentOTP(result['myOTP']);
            debugPrint('OTP enviado a ${registerCubit.state.email}');
          } else {
            debugPrint('Fallo al enviar OTP');
          }
        } catch (e) {
          debugPrint('Error enviando OTP: $e');
        }
      }
      // registerCubit.updateEmailVerification();
      // registerCubit.setCurrentOTP();
      break;

    case RegisterStatusProgress.emailVerification:
      debugPrint('Puede que cambie de telefo\nemailVerification');
      if (userResponse == registerCubit.state.currentOTP) {
        registerCubit.updateEmailVerification(EmailVerification.success);
      }
      // registerCubit.updateEmailVerification();
      // registerCubit.setCurrentOTP();
      break;

    case RegisterStatusProgress.avatarUrl:
      debugPrint('Manejar eel archivo');
      // registerCubit.setAvatarFile();
      // registerCubit.setAvatarUrl();
      break;

    case RegisterStatusProgress.phone:
      debugPrint('Ingresar telefono');
      registerCubit.setPhone(userResponse!);
      break;

    case RegisterStatusProgress.voiceNoteUrl:
      debugPrint('Manejar el archivo');
      // registerCubit.setVoiceNoteFile();
      // registerCubit.setVoiceNoteUrl();
      break;

    default:
      debugPrint('➡️ Otro paso detectado: $step');
  }
}

RegisterStatusProgress _parseStep(String raw) {
  if (raw.contains('language')) return RegisterStatusProgress.language;
  if (raw.contains('fullname') || raw.contains('full name')) {
    return RegisterStatusProgress.fullName;
  }
  if (raw.contains('username')) return RegisterStatusProgress.username;
  if (raw.contains('gender')) return RegisterStatusProgress.gender;
  if (raw.contains('social') || raw.contains('ecosystem')) {
    return RegisterStatusProgress.socialEcosystem;
  }
  if (raw.contains('location')) return RegisterStatusProgress.location;
  if (raw.contains('sendotp')) {
    return RegisterStatusProgress.sendOTP; // 👈 AÑADIDO
  }
  if (raw.contains('email')) return RegisterStatusProgress.emailVerification;
  if (raw.contains('avatar')) return RegisterStatusProgress.avatarUrl;
  if (raw.contains('phone')) return RegisterStatusProgress.phone;
  if (raw.contains('voice')) return RegisterStatusProgress.voiceNoteUrl;
  if (raw.contains('category')) return RegisterStatusProgress.category;
  if (raw.contains('interest')) return RegisterStatusProgress.interests;
  if (raw.contains('done')) return RegisterStatusProgress.done;
  return RegisterStatusProgress.emty;
}
