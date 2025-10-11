import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/services/send_otp.dart';

Future<Map<String, dynamic>?> processBotResponse(
  Map<String, dynamic> resp, {
  required RegisterCubit registerCubit,
}) async {
  final String stepRaw = (resp['step'] ?? '').toString().toLowerCase();
  final RegisterStatusProgress step = _parseStep(stepRaw);

  final bool? isValid = resp['valid'];
  final String? userResponse = resp['userResponse'];

  debugPrint('📩 [processBotResponse]');
  debugPrint('   • stepRaw: "$stepRaw"');
  debugPrint('   • step: $step');
  debugPrint('   • valid: $isValid');
  debugPrint('   • userResponse: $userResponse');
  debugPrint('----------------------------------------');

  switch (step) {
    case RegisterStatusProgress.language:
      if (isValid == true && userResponse != null) {
        registerCubit.setLanguage(userResponse);
        debugPrint('✅ Idioma guardado: $userResponse');
      }
      break;

    case RegisterStatusProgress.fullName:
      if (isValid == true && userResponse != null) {
        registerCubit.setFullName(userResponse);
        debugPrint('✅ Nombre completo guardado: $userResponse');
      }
      break;

    case RegisterStatusProgress.username:
      if (isValid == true && userResponse != null) {
        registerCubit.setUsername(userResponse);
        debugPrint('✅ Username guardado: $userResponse');
      }
      break;

    case RegisterStatusProgress.gender:
      if (isValid == true && userResponse != null) {
        registerCubit.setGender(userResponse);
        debugPrint('✅ Género guardado: $userResponse');
      }
      break;

    case RegisterStatusProgress.socialEcosystem:
      debugPrint('📱 Paso de redes sociales - se maneja en navigation handler');
      break;

    case RegisterStatusProgress.location:
      if (isValid == true) {
        // Si ya tiene ubicación del inicio, solo actualiza el progreso
        if (registerCubit.state.location != null) {
          registerCubit.setVerifyLocation();
          debugPrint(
            '✅ Ubicación confirmada: ${registerCubit.state.location!.city}',
          );
        }
      } else {
        debugPrint('❌ Usuario rechazó la ubicación');
        // Aquí podrías solicitar ubicación manual
        return {
          "needsManualLocation": true,
          "message": "Por favor, ingresa tu ciudad manualmente",
        };
      }
      break;

    case RegisterStatusProgress.sendOTP:
      if (isValid == true) {
        // Usuario confirmó el email
        if (registerCubit.state.email != null) {
          try {
            debugPrint('📧 Enviando OTP a: ${registerCubit.state.email}');
            final result = await sendOTP(email: registerCubit.state.email!);

            if (result['sent'] == true) {
              registerCubit.setCurrentOTP(result['myOTP']);
              debugPrint('✅ OTP enviado: ${result['myOTP']}');
              return {"otpSent": true};
            } else {
              debugPrint('❌ Fallo al enviar OTP');
              return {
                "error": true,
                "message": "Error al enviar el código. Intenta nuevamente.",
              };
            }
          } catch (e) {
            debugPrint('❌ Error enviando OTP: $e');
            return {
              "error": true,
              "message": "Error de conexión. Verifica tu internet.",
            };
          }
        }
      } else {
        // Usuario quiere cambiar email
        debugPrint('📝 Usuario solicitó cambiar email');
        return {
          "changeEmail": true,
          "message": "De acuerdo, ingresa tu nuevo correo electrónico",
        };
      }
      break;

    case RegisterStatusProgress.emailVerification:
      if (isValid == true && userResponse != null) {
        // ✅ NUEVO: Si es "continue", solo es confirmación del mensaje de éxito
        if (userResponse.toLowerCase() == 'continue') {
          debugPrint('✅ Usuario confirmó mensaje de éxito, avanzando...');
          return null; // No hacer nada, solo permitir avanzar
        }

        // Validar OTP normalmente
        final storedOTP = registerCubit.state.currentOTP;

        debugPrint(
          '🔍 Comparando OTP: ingresado=$userResponse, esperado=$storedOTP',
        );

        if (userResponse == storedOTP) {
          registerCubit.updateEmailVerification(EmailVerification.success);
          debugPrint('✅ Email verificado correctamente');
          return {"verified": true};
        } else {
          debugPrint('❌ OTP incorrecto');
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "error": true,
            "invalidOTP": true,
            "message": isSpanish
                ? "❌ Código incorrecto. Por favor verifica e intenta nuevamente."
                : "❌ Incorrect code. Please verify and try again.",
          };
        }
      }
      break;

    case RegisterStatusProgress.avatarUrl:
      // Las fotos se manejan en el controller/navigation handler
      if (userResponse != null && userResponse.isNotEmpty) {
        registerCubit.setAvatarUrl(userResponse);
        debugPrint('✅ Avatar guardado: $userResponse');
      } else {
        debugPrint('⚠️ No se proporcionó avatar, continuando sin foto');
      }
      break;

    case RegisterStatusProgress.phone:
      if (isValid == true && userResponse != null) {
        registerCubit.setPhone(userResponse);
        debugPrint('✅ Teléfono guardado: $userResponse');
      }
      break;

    case RegisterStatusProgress.voiceNoteUrl:
      // El audio ya se guardó como File en el handler
      // Solo validamos que el archivo exista
      if (userResponse != null && userResponse.isNotEmpty) {
        final audioFile = File(userResponse);
        if (await audioFile.exists()) {
          debugPrint('✅ Audio validado: $userResponse');
          // El archivo ya está guardado con setVoiceNoteFile
          // El progreso se actualiza automáticamente en GeminiService
        } else {
          debugPrint('⚠️ Archivo de audio no encontrado');
          return {
            "error": true,
            "message":
                "No se pudo encontrar el archivo de audio. Por favor, graba nuevamente.",
          };
        }
      } else {
        debugPrint('⚠️ No se proporcionó nota de voz');
      }
      break;

    case RegisterStatusProgress.category:
      debugPrint('🎯 Navegando a selección de categorías');
      break;

    default:
      debugPrint('➡️ Paso no manejado: $step');
  }

  return null;
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
  if (raw.contains('sendotp')) return RegisterStatusProgress.sendOTP;

  // ✅ IMPORTANTE: emailSuccess también mapea a emailVerification
  // porque ambos manejan el flujo de verificación de email
  if (raw.contains('emailsuccess') ||
      raw.contains('otpinput') ||
      raw.contains('email')) {
    return RegisterStatusProgress.emailVerification;
  }

  if (raw.contains('avatar')) return RegisterStatusProgress.avatarUrl;
  if (raw.contains('phone')) return RegisterStatusProgress.phone;
  if (raw.contains('voice')) return RegisterStatusProgress.voiceNoteUrl;
  if (raw.contains('done')) return RegisterStatusProgress.doneChat;
  return RegisterStatusProgress.emty;
}
