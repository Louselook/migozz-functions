import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
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

    // case RegisterStatusProgress.gender:
    //   if (isValid == true && userResponse != null) {
    //     registerCubit.setGender(userResponse);
    //     debugPrint('✅ Género guardado: $userResponse');
    //   }
    //   break;

    // case RegisterStatusProgress.socialEcosystem:
    //   debugPrint('📱 Paso de redes sociales - se maneja en navigation handler');
    //   break;

    case RegisterStatusProgress.location:
      debugPrint('📍 [processBotResponse] Procesando ubicación');
      debugPrint('📍 [processBotResponse] isValid: $isValid');
      debugPrint(
        '📍 [processBotResponse] confirmLocation: ${resp['confirmLocation']}',
      );
      debugPrint(
        '📍 [processBotResponse] emptyLocation: ${resp['emptyLocation']}',
      );

      // Si es un prompt del bot para ingresar ubicación manual, no procesar como respuesta.
      if (resp['manualLocationPrompt'] == true) {
        debugPrint('📍 [processBotResponse] Manual location prompt (skip)');
        return null;
      }

      // Si no hay validación ni flags, probablemente es una pregunta/prompt.
      final hasAnyFlag =
          resp['manualLocation'] == true ||
          resp['confirmLocation'] == true ||
          resp['emptyLocation'] == true;
      if (isValid == null && !hasAnyFlag) {
        debugPrint(
          '📍 [processBotResponse] Location prompt without flags (skip)',
        );
        return null;
      }

      // Ubicación manual
      if (resp['manualLocation'] == true && isValid == true) {
        final country = (resp['country'] ?? '').toString().trim();
        final state = (resp['state'] ?? '').toString().trim();
        final city = (resp['city'] ?? '').toString().trim();
        if (country.isNotEmpty && state.isNotEmpty && city.isNotEmpty) {
          registerCubit.setLocation(
            LocationDTO(
              country: country,
              state: state,
              city: city,
              lat: 0.0,
              lng: 0.0,
            ),
          );
          debugPrint('✅ Ubicación manual guardada: $city, $state, $country');
          // Avanzar el progreso igual que cuando se confirma ubicación.
          registerCubit.confirmLocation();
          return null;
        }
      }

      // Opción 1: Usuario confirmó ubicación (Sí)
      if (resp['confirmLocation'] == true && isValid == true) {
        if (registerCubit.state.location != null) {
          registerCubit.confirmLocation();
          debugPrint(
            '✅ Ubicación confirmada: ${registerCubit.state.location!.city}, ${registerCubit.state.location!.country}',
          );
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
        debugPrint(
          '✅ Usuario rechazó ubicación - guardando LocationDTO.empty()',
        );
        return null; // Sin errores, avanza al siguiente paso
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

    case RegisterStatusProgress.email:
      if (isValid == true && userResponse != null) {
        registerCubit.setEmail(userResponse.trim());
        debugPrint('✅ Email guardado: $userResponse');
        return null; // Sin errores, avanza al siguiente paso (sendOTP)
      } else {
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "error": true,
          "message": isSpanish
              ? "Por favor ingresa un correo electrónico válido."
              : "Please enter a valid email address.",
        };
      }

    case RegisterStatusProgress.sendOTP:
      // Caso 1: Usuario quiere cambiar email (dijo "No")
      if (resp['changeEmail'] == true) {
        debugPrint('📝 Usuario solicitó cambiar email');
        return {
          "changeEmail": true,
          "message": registerCubit.state.language == 'Español'
              ? "De acuerdo, ingresa tu nuevo correo electrónico"
              : "Okay, please enter your new email address",
        };
      }

      // Caso 2: Usuario confirmó el email (dijo "Sí")
      if (isValid == true) {
        // Usuario confirmó el email
        if (registerCubit.state.email != null) {
          try {
            // Convert language label to code: 'Español' -> 'es', otherwise 'en'
            final langCode = registerCubit.state.language == 'Español'
                ? 'es'
                : 'en';
            debugPrint(
              '📧 Enviando OTP a: ${registerCubit.state.email} (lang: $langCode)',
            );
            final result = await sendOTP(
              email: registerCubit.state.email!,
              language: langCode,
            );

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
        // Respuesta inválida
        debugPrint('❌ Respuesta inválida en sendOTP');
        return {
          "error": true,
          "message": registerCubit.state.language == 'Español'
              ? "Por favor responde 'Sí' o 'No'."
              : "Please answer 'Yes' or 'No'.",
        };
      }
      break;

    case RegisterStatusProgress.emailChange:
      if (isValid == true && userResponse != null) {
        // Guardar el nuevo email
        final newEmail = userResponse.trim();
        registerCubit.setEmail(newEmail);
        debugPrint('✅ Nuevo email guardado: $newEmail');

        // Retornar indicador para que se vuelva a pedir confirmación
        return {
          "emailChanged": true,
          "message": registerCubit.state.language == 'Español'
              ? "Email actualizado. Verificando..."
              : "Email updated. Verifying...",
        };
      } else {
        // Email inválido
        final isSpanish = registerCubit.state.language == 'Español';
        return {
          "error": true,
          "message": isSpanish
              ? "❌ Por favor ingresa un correo electrónico válido."
              : "❌ Please enter a valid email address.",
        };
      }
      // ignore: dead_code
      break;

    case RegisterStatusProgress.emailVerification:
      if (isValid == true && userResponse != null) {
        // Si es "continue", solo es confirmación del mensaje de éxito
        if (userResponse.toLowerCase() == 'continue') {
          debugPrint('✅ Usuario confirmó mensaje de éxito, avanzando...');
          return null; // No hacer nada, solo permitir avanzar
        }

        // Opción 1: Usuario quiere reenviar código
        if (resp['resendCode'] == true) {
          debugPrint('📧 Usuario solicitó reenviar código OTP');
          if (registerCubit.state.email != null) {
            try {
              // Convert language label to code: 'Español' -> 'es', otherwise 'en'
              final langCode = registerCubit.state.language == 'Español'
                  ? 'es'
                  : 'en';
              debugPrint(
                '📧 Reenviando OTP a: ${registerCubit.state.email} (lang: $langCode)',
              );
              final result = await sendOTP(
                email: registerCubit.state.email!,
                language: langCode,
              );

              if (result['sent'] == true) {
                registerCubit.setCurrentOTP(result['myOTP']);
                debugPrint('✅ OTP reenviado: ${result['myOTP']}');
                return {
                  "otpResent": true,
                  "message": registerCubit.state.language == 'Español'
                      ? "✅ Se ha reenviado un código de 6 dígitos a tu correo."
                      : "✅ A 6-digit code has been resent to your email.",
                };
              } else {
                debugPrint('❌ Fallo al reenviar OTP');
                return {
                  "error": true,
                  "message": registerCubit.state.language == 'Español'
                      ? "Error al reenviar el código. Intenta nuevamente."
                      : "Error resending code. Please try again.",
                };
              }
            } catch (e) {
              debugPrint('❌ Error reenviando OTP: $e');
              return {
                "error": true,
                "message": registerCubit.state.language == 'Español'
                    ? "Error de conexión. Verifica tu internet."
                    : "Connection error. Check your internet.",
              };
            }
          }
        }

        // Opción 2: Usuario quiere cambiar correo desde la pantalla de OTP
        if (resp['changeEmailFromOTP'] == true) {
          debugPrint('📧 Usuario solicitó cambiar email desde pantalla de OTP');
          return {
            "changeEmailFromOTP": true,
            "message": registerCubit.state.language == 'Español'
                ? "De acuerdo, ingresa tu nuevo correo electrónico"
                : "Okay, please enter your new email address",
          };
        }

        // Opción 3: Validar OTP normalmente
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

    case RegisterStatusProgress.socialEcosystem:
      // Las redes sociales se manejan en el navigation handler
      // Aquí solo validamos que el flujo avance correctamente
      debugPrint('📱 [processBotResponse] Paso de redes sociales procesado');
      if (userResponse != null && userResponse.isNotEmpty) {
        debugPrint(
          '📱 Respuesta del usuario en socialEcosystem: $userResponse',
        );
        // El ecosistema social se actualiza desde SocialNetworkCubit directamente
        // No necesitamos hacer nada aquí excepto permitir que el flujo continúe
      }
      break;

    case RegisterStatusProgress.avatarUrl:
      // Las fotos se manejan en el controller/navigation handler
      // Detectar si el usuario quiere usar una foto de red social específica
      if (userResponse != null && userResponse.isNotEmpty) {
        // Si es una URL, guardarla directamente
        if (userResponse.startsWith('http')) {
          registerCubit.setAvatarUrl(userResponse);
          debugPrint('✅ Avatar URL guardada: $userResponse');
        } else {
          // Si no es URL, podría ser una selección de plataforma o archivo local
          debugPrint('📸 Procesando respuesta de avatar: $userResponse');
        }
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
      // Si el usuario hizo Skip, no hay archivo de audio pero es válido
      if (userResponse?.toLowerCase() == 'skip') {
        debugPrint('⏭️ Usuario skipeo la nota de voz');
        // Skip es válido, no requerir archivo de audio
      } else if (userResponse != null && userResponse.isNotEmpty) {
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
  // if (raw.contains('gender')) return RegisterStatusProgress.gender;

  // Habilitar socialEcosystem y avatarUrl para que el flujo los maneje correctamente
  if (raw.contains('socialecosystem') || raw.contains('social')) {
    return RegisterStatusProgress.socialEcosystem;
  }
  if (raw.contains('location')) return RegisterStatusProgress.location;
  if (raw.contains('sendotp')) return RegisterStatusProgress.sendOTP;
  if (raw.contains('emailchange')) return RegisterStatusProgress.emailChange;

  // IMPORTANTE: emailSuccess también mapea a emailVerification
  // porque ambos manejan el flujo de verificación de email
  if (raw.contains('emailsuccess') ||
      raw.contains('otpinput') ||
      raw.contains('email')) {
    return RegisterStatusProgress.emailVerification;
  }

  // Habilitar avatarUrl para manejar selección de fotos
  if (raw.contains('avatarurl') || raw.contains('avatar')) {
    return RegisterStatusProgress.avatarUrl;
  }
  if (raw.contains('phone')) return RegisterStatusProgress.phone;
  if (raw.contains('voice')) return RegisterStatusProgress.voiceNoteUrl;
  if (raw.contains('done')) return RegisterStatusProgress.doneChat;
  return RegisterStatusProgress.emty;
}
