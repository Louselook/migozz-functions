import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:migozz_app/core/config/api/api_config.dart';

enum MediaType { avatar, voice, video, document }

class UserMediaService {
  /// 🔹 Sube archivos (usando el email como identificador temporal)
  Future<Map<MediaType, String>> uploadFilesTemporarily({
    required String email,
    required Map<MediaType, File> files,
  }) async {
    final urls = <MediaType, String>{};

    for (final entry in files.entries) {
      final file = entry.value;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBase}/users/upload-file'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['folder'] = entry.key.name; // avatar, voice, etc.
      request.fields['user_id'] = email; // 🔹 email temporal

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        urls[entry.key] = data['url']; // URL pública devuelta por FastAPI
      } else {
        throw Exception('Error subiendo archivo: ${response.body}');
      }
    }

    return urls;
  }

  /// 🔹 Asocia los archivos temporales subidos con el email al UID final del usuario.
  /// Usa el endpoint del backend FastAPI (`/users/associate-media`) para moverlos en el bucket.
  Future<Map<MediaType, String>> associateMediaToUid({
    required String uid,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBase}/users/associate-media'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error asociando archivos: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception('Error en respuesta del backend: ${data['message']}');
    }

    // Si tu backend devuelve URLs, las parseamos
    final urls = <MediaType, String>{};
    if (data['urls'] != null) {
      for (final url in List<String>.from(data['urls'])) {
        if (url.contains('avatar')) urls[MediaType.avatar] = url;
        if (url.contains('voice')) urls[MediaType.voice] = url;
      }
    }

    debugPrint('✅ [MediaService] Archivos asociados correctamente via backend');
    return urls;
  }

  /// Método genérico para subir con UID directamente (si el usuario ya está registrado)
  Future<Map<MediaType, String>> uploadFiles({
    required String uid,
    required Map<MediaType, File> files,
  }) async {
    final urls = <MediaType, String>{};

    for (final entry in files.entries) {
      final file = entry.value;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBase}/users/upload-file'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['folder'] = entry.key.name;
      request.fields['user_id'] = uid; // 🔹 ahora usamos UID

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        urls[entry.key] = data['url'];
      } else {
        throw Exception('Error subiendo archivo: ${response.body}');
      }
    }

    return urls;
  }
}
