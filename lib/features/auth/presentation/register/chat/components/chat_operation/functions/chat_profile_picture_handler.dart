import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/controller/chat_controller.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';

class ChatProfilePictureHandler {
  final RegisterCubit cubit;
  final ChatControllerTest controller;

  ChatProfilePictureHandler({required this.cubit, required this.controller});

  /// Inicia el flujo de selección de avatar
  Future<void> startAvatarFlow() async {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    // 🔹 Mensaje 1: Felicitación por perfil activado
    controller.addMessage({
      "other": true,
      "text": isSpanish
          ? "¡Felicidades! ¡Tu perfil ya está activado! 🎉"
          : "Congratulations! Your profile is now activated! 🎉",
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    // 🔹 Mensaje 2: Personalizar perfil
    controller.addMessage({
      "other": true,
      "text": isSpanish
          ? "Personalicemos tu perfil. Puedo sugerirte una foto de tus redes sociales conectadas o puedes subir una nueva. ¿Cuál prefieres? 📸"
          : "Let's personalize your profile. I can suggest a photo from your connected social media or you can upload a new one. Which do you prefer? 📸",
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // 🔹 Mensaje 3: Mostrar tarjetas de fotos disponibles
    await _showAvailablePictures();
  }

  /// Muestra las tarjetas de fotos disponibles de las redes sociales
  Future<void> _showAvailablePictures() async {
    final platforms = cubit.state.socialEcosystem ?? [];
    if (platforms.isEmpty) {
      debugPrint('⚠️ No hay redes sociales conectadas');
      _showUploadOptions();
      return;
    }

    final pictureCards = <Map<String, String>>[];

    for (final platform in platforms) {
      final key = platform.keys.first; // "youtube", "instagram"
      final data = platform[key] as Map<String, dynamic>;

      // Buscar imagen de perfil
      final possibleKeys = [
        "profile_image_url",
        "profile_pic_url",
        "avatar_url",
        "picture",
      ];

      String? imageUrl;
      for (final imgKey in possibleKeys) {
        if (data[imgKey] != null && (data[imgKey] as String).isNotEmpty) {
          imageUrl = data[imgKey] as String;
          break;
        }
      }

      if (imageUrl != null) {
        final label =
            data["title"] ??
            data["username"] ??
            data["full_name"] ??
            key.toUpperCase();

        pictureCards.add({
          "imageUrl": imageUrl,
          "label": label,
          "platform": key, // Para identificar la plataforma al seleccionar
        });
      }
    }

    if (pictureCards.isEmpty) {
      debugPrint('⚠️ No se encontraron fotos de perfil en las redes');
      _showUploadOptions();
      return;
    }

    // 🔹 Añadir mensaje de tipo pictureCard
    controller.addMessage({
      "other": true,
      "type": MessageType.pictureCard,
      "pictures": pictureCards,
      "time": getTimeNow(),
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // 🔹 Añadir opciones de acción
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    controller.addMessage({
      "other": true,
      "text": isSpanish
          ? "Selecciona una foto tocándola o elige subir/tomar una nueva:"
          : "Select a photo by tapping it or choose to upload/take a new one:",
      "options": _getAvatarOptions(isSpanish),
      "type": MessageType.text,
      "time": getTimeNow(),
    });
  }

  /// Opciones de subida/captura
  void _showUploadOptions() {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    controller.addMessage({
      "other": true,
      "text": isSpanish
          ? "No encontré fotos en tus redes. Puedes subir o tomar una nueva:"
          : "I didn't find photos in your networks. You can upload or take a new one:",
      "options": _getAvatarOptions(isSpanish),
      "type": MessageType.text,
      "time": getTimeNow(),
    });
  }

  List<String> _getAvatarOptions(bool isSpanish) {
    return isSpanish
        ? ['Subir foto', 'Tomar foto']
        : ['Upload photo', 'Take photo'];
  }

  /// Maneja la selección del usuario
  Future<void> handleAvatarSelection(String selection) async {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');
    final lower = selection.toLowerCase().trim();

    // 🔹 Usuario eligió subir foto
    if (lower.contains('subir') || lower.contains('upload')) {
      await _pickAndUploadAvatar(
        source: ImageSource.gallery,
        isSpanish: isSpanish,
      );
      return;
    }

    // 🔹 Usuario eligió tomar foto
    if (lower.contains('tomar') || lower.contains('take')) {
      await _pickAndUploadAvatar(
        source: ImageSource.camera,
        isSpanish: isSpanish,
      );
      return;
    }

    // 🔹 Si no es opción de subida/toma, puede ser selección directa de URL
    // Esta parte se maneja desde el tap en las picture cards (ver más abajo)
  }

  /// Maneja el tap en una picture card
  Future<void> handlePictureCardTap(String imageUrl, String platform) async {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    // Guardar la URL como avatar
    cubit.setAvatarUrl(imageUrl);

    controller.addMessage({
      "other": true,
      "text": isSpanish
          ? "✅ Perfecto! Usaré tu foto de ${platform.toUpperCase()} como avatar."
          : "✅ Perfect! I'll use your ${platform.toUpperCase()} photo as your avatar.",
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    // Continuar con el siguiente paso
    await Future.delayed(const Duration(milliseconds: 1000));
    controller.showNextBotMessage();
  }

  /// Sube una imagen desde galería o cámara
  Future<void> _pickAndUploadAvatar({
    required ImageSource source,
    required bool isSpanish,
  }) async {
    try {
      controller.addMessage({
        "other": true,
        "type": MessageType.typing,
        "name": "Migozz",
        "time": getTimeNow(),
      });

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );

      // Remover typing
      controller.messages.removeWhere(
        (msg) => msg["type"] == MessageType.typing,
      );

      if (picked == null) {
        controller.addMessage({
          "other": true,
          "text": isSpanish
              ? "No seleccionaste ninguna imagen."
              : "No image selected.",
          "type": MessageType.text,
          "time": getTimeNow(),
        });
        return;
      }

      // Mostrar imagen seleccionada como preview
      controller.addMessage({
        "other": true,
        "type": MessageType.pictureCard,
        "pictures": [
          {"imageUrl": picked.path, "label": "Preview"},
        ],
        "time": getTimeNow(),
      });

      // Guardar file temporal en cubit
      final file = File(picked.path);
      cubit.setAvatarFile(file);

      if (cubit.state.email == null) {
        controller.addMessage({
          "other": true,
          "text": isSpanish
              ? "Aún no tengo tu email para subir la imagen."
              : "I don't have your email yet to upload the image.",
          "type": MessageType.text,
          "time": getTimeNow(),
        });
        return;
      }

      // Subir archivo
      controller.addMessage({
        "other": true,
        "type": MessageType.typing,
        "name": "Migozz",
        "time": getTimeNow(),
      });

      final mediaService = UserMediaService();
      final result = await mediaService.uploadFilesTemporarily(
        email: cubit.state.email!,
        files: {MediaType.avatar: file},
      );

      controller.messages.removeWhere(
        (msg) => msg["type"] == MessageType.typing,
      );

      final url = result[MediaType.avatar];
      if (url != null) {
        cubit.setAvatarUrl(url);
        controller.addMessage({
          "other": true,
          "text": isSpanish
              ? "✅ Avatar subido correctamente."
              : "✅ Avatar uploaded successfully.",
          "type": MessageType.text,
          "time": getTimeNow(),
        });

        // Continuar con el siguiente paso
        await Future.delayed(const Duration(milliseconds: 1000));
        controller.showNextBotMessage();
      } else {
        controller.addMessage({
          "other": true,
          "text": isSpanish
              ? "❌ Error al subir el avatar."
              : "❌ Error uploading avatar.",
          "type": MessageType.text,
          "time": getTimeNow(),
        });
      }
    } catch (e) {
      controller.messages.removeWhere(
        (msg) => msg["type"] == MessageType.typing,
      );

      controller.addMessage({
        "other": true,
        "text": isSpanish ? "❌ Falló la subida: $e" : "❌ Upload failed: $e",
        "type": MessageType.text,
        "time": getTimeNow(),
      });
    }
  }
}

// 🔹 Extensión para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
