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
  debugPrint('   • confirmLocation: ${resp['confirmLocation']}');
  debugPrint('   • emptyLocation: ${resp['emptyLocation']}');
  debugPrint('----------------------------------------');

  switch (step) {
    // case RegisterStatusProgress.language:
    //   if (isValid == true && userResponse != null) {
    //     registerCubit.setLanguage(userResponse);
    //     debugPrint(' Idioma guardado: $userResponse');
    //   }
    //   break;

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
      debugPrint('📍 [processBotResponse] Procesando ubicación');
      debugPrint('📍 [processBotResponse] isValid: $isValid');
      debugPrint('📍 [processBotResponse] confirmLocation: ${resp['confirmLocation']}');
      debugPrint('📍 [processBotResponse] emptyLocation: ${resp['emptyLocation']}');
      
      // Opción 1: Usuario confirmó ubicación (Sí)
      if (resp['confirmLocation'] == true && isValid == true) {
        if (registerCubit.state.location != null) {
          registerCubit.confirmLocation();
          debugPrint('✅ Ubicación confirmada: ${registerCubit.state.location!.city}, ${registerCubit.state.location!.country}');
          return null; // Sin errores, avanza al siguiente paso
        } else {
          debugPrint('⚠️ No hay ubicación para confirmar');
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "error": true,
            "message": isSpanish
                ? "No pudimos detectar tu ubicación. Intenta nuevamente."
                : "We couldn't detect your location. Please try again.",
          };
        }
      }
      
      // Opción 2: Usuario rechazó usar ubicación (No)
      else if (resp['emptyLocation'] == true && isValid == true) {
        registerCubit.rejectLocation();
        debugPrint('✅ Usuario rechazó ubicación - guardando LocationDTO.empty()');
        return null; // Sin errores, avanza al siguiente paso
      }
      
      // Opción 3: Ubicación incorrecta o respuesta inválida
      else if (isValid == false) {
        debugPrint('⚠️ Ubicación incorrecta o respuesta inválida');
        // El mensaje de error ya viene en resp['text'] desde _evaluateLocation
        // GeminiService se encargará de mostrarlo
        return null;
      }
      
      // Caso inesperado
      else {
        debugPrint('⚠️ Caso de ubicación no manejado');
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "error": true,
          "message": isSpanish
              ? "Respuesta no válida. Por favor, selecciona una opción."
              : "Invalid response. Please select an option.",
        };
      }

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
        // Si es "continue", solo es confirmación del mensaje de éxito
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
      // El audio ya fue confirmado y guardado por el handler
      if (userResponse != null && userResponse.isNotEmpty) {
        // Verificar que el archivo existe en el cubit
        final voiceFile = registerCubit.voiceNoteFile;

        if (voiceFile != null && await voiceFile.exists()) {
          debugPrint('✅ Audio confirmado y validado: ${voiceFile.path}');
          debugPrint('✅ Tamaño: ${await voiceFile.length()} bytes');
        } else {
          debugPrint('⚠️ Archivo de audio no encontrado en cubit');
          final isSpanish = registerCubit.state.language == 'Español';
          return {
            "error": true,
            "message": isSpanish
                ? "No se pudo encontrar el archivo de audio. Por favor, graba nuevamente."
                : "Could not find the audio file. Please record again.",
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

  // IMPORTANTE: emailSuccess también mapea a emailVerification
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