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
  // Nota: botIndex es 1-based según el flujo conceptual.
  // El currentIndex interno de IaChatService podría ser 0-based.
  // Asegúrate de que al llamar este método estés pasando el índice que corresponde
  // a la pregunta mostrada al usuario.

  final trimmed = userResponse.trim();

  switch (botIndex) {
    // 1) Idioma
    case 1:
      cubit.setLanguage(trimmed);
      break;

    // 2) Nombre completo
    case 2:
      cubit.setFullName(trimmed);
      break;

    // 3) Username / Apodo
    case 3:
      cubit.setUsername(trimmed);
      break;

    // 4) Género (después se navega a redes sociales fuera de este switch)
    case 4:
      cubit.setGender(trimmed);
      break;

    // 5) Acción social (se maneja fuera con action=0)
    // 6) Resumen social (dinamicResponse SocialEcosystemStep)
    // No se mapean aquí porque no guardan un valor directo.

    // 7) Confirmación de ubicación
    case 7:
      // Si el usuario responde NO podrías marcar location como null para forzar una re-obtención.
      if (!parseYesNo(trimmed)) {
        // Ejemplo: cubit.updateLocation(null); // si quisieras forzar re-cálculo
      } else {
        // Confirmada: no hacemos nada porque ya se estableció al iniciar.
      }
      break;

    // 8) Confirmación de email -> Siempre envía OTP (puedes condicionar si quieres)
    case 8:
      // Podrías agregar aquí lógica para cambiar email si la respuesta es NO.
      // if (!parseYesNo(trimmed)) { ... pedir nuevo email en la UI ... }
      if (cubit.state.email != null) {
        try {
          final result = await sendOTP(email: cubit.state.email!);
          if (result['sent'] == true) {
            cubit.setCurrentOTP(result['myOTP']);
            debugPrint('OTP enviado a ${cubit.state.email}');
          } else {
            debugPrint('Fallo al enviar OTP');
          }
        } catch (e) {
          debugPrint('Error enviando OTP: $e');
        }
      }
      break;

    // 9) Validación OTP
    case 9:
      if (trimmed == cubit.state.currentOTP) {
        cubit.updateEmailVerification(EmailVerification.success);
      }
      break;

    // 10) Activado (dinamicResponse FollowedMessages) - sin mapeo directo
    // 11-12-13) Flujo Avatar. Solo en 13 esperamos la selección final.
    case 13:
      // Selección de avatar.
      final lower = trimmed.toLowerCase();
      final platforms = cubit.state.socialEcosystem ?? [];
      bool matchedPlatform = false;
      for (final p in platforms) {
        final key = p.keys.first; // ej: instagram
        if (lower == key.toLowerCase()) {
          final data = p[key] as Map<String, dynamic>;
          final avatar = data['profile_image_url']?.toString();
          if (avatar != null && avatar.isNotEmpty) {
            cubit.setAvatarUrl(avatar);
            matchedPlatform = true;
          }
          break;
        }
      }
      if (!matchedPlatform) {
        final isSpanish = (cubit.state.language ?? '').toLowerCase().contains(
          'es',
        );
        final uploadKeywords = isSpanish
            ? ['subir', 'subir foto', 'cargar', 'cargar foto']
            : ['upload', 'upload photo', 'add photo'];
        if (uploadKeywords.contains(lower)) {
          // Aquí podrías disparar un action en UI; de momento no hacemos nada más
        } else {
          // userResponse puede ser una ruta local o una URL ya asignada.
          final file = File(trimmed);
          if (await file.exists()) {
            cubit.setAvatarFile(file); // se subirá luego en checkCompletion
          } else if (Uri.tryParse(trimmed)?.hasAbsolutePath == true) {
            cubit.setAvatarUrl(trimmed); // ya es una URL directa
          }
        }
      }
      break;

    // 14) Teléfono
    case 14:
      cubit.setPhone(trimmed);
      await cubit.checkCompletion();
      break;

    // 15) Nota de voz (ruta local archivo) o texto (ignorar)
    case 15:
      final audioFile = File(trimmed);
      if (await audioFile.exists()) {
        cubit.setVoiceNoteFile(audioFile);
      }
      await cubit.checkCompletion();
      break;

    // 16) Categorías (lista simple separada por comas)
    case 16:
      final categories = _parseSimpleList(trimmed);
      if (categories.isNotEmpty) {
        cubit.setCategories(categories);
      }
      await cubit.checkCompletion();
      break;

    // 17) Intereses (mapa category->lista de intereses)
    case 17:
      final interests = _parseInterestsMap(trimmed);
      if (interests.isNotEmpty) {
        cubit.setInterests(interests);
      }
      await cubit.checkCompletion();
      break;

    // 18) Finishing (sin mapeo) - 19) Complete (sin mapeo)
    default:
      break;
  }
}

// ------------------ Helpers de parsing ------------------

/// Parsea una lista simple "music, sports, tech" => ["music","sports","tech"]
List<String> _parseSimpleList(String input) {
  return input
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Parsea intereses en formato: "music: rock, pop; sports: football, tennis"
Map<String, List<String>> _parseInterestsMap(String input) {
  final Map<String, List<String>> out = {};
  final segments = input.split(';');
  for (final raw in segments) {
    final part = raw.trim();
    if (part.isEmpty) continue;
    final kv = part.split(':');
    if (kv.length != 2) continue;
    final key = kv[0].trim();
    if (key.isEmpty) continue;
    final values = kv[1]
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (values.isNotEmpty) out[key] = values;
  }
  return out;
}

bool parseYesNo(String userResponse) {
  final normalized = userResponse.trim().toLowerCase();

  const affirmative = ['si', 's', 'yes', 'y'];

  // Solo retorna true si es afirmativo, cualquier otra cosa es false
  return affirmative.contains(normalized);
}
