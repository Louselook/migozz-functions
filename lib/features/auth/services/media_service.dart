import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:migozz_app/core/config/api/api_config.dart';

enum MediaType { avatar, voice, video, document }

class UserMediaService {
  // Sube archivos (usando el email como identificador temporal)
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
      request.fields['user_id'] = email; // email temporal

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

  // Asocia los archivos temporales subidos con el email al UID final del usuario.
  Future<Map<MediaType, String>> associateMediaToUid({
    required String uid,
    required String email,
  }) async {
    debugPrint('🔄 [MediaService] Iniciando asociación de media...');
    debugPrint('🔄 [MediaService] UID: $uid');
    debugPrint('🔄 [MediaService] Email: $email');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBase}/users/associate-media'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'email': email}),
      );

      debugPrint('🔄 [MediaService] Response status: ${response.statusCode}');
      debugPrint('🔄 [MediaService] Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error asociando archivos: ${response.body}');
      }

      final data = jsonDecode(response.body);
      debugPrint('🔄 [MediaService] Parsed data: $data');

      if (data['success'] != true) {
        throw Exception('Error en respuesta del backend: ${data['message']}');
      }

      // Si tu backend devuelve URLs, las parseamos
      final urls = <MediaType, String>{};
      if (data['urls'] != null) {
        debugPrint('🔄 [MediaService] URLs encontradas: ${data['urls']}');

        for (final url in List<String>.from(data['urls'])) {
          if (url.contains('avatar')) {
            urls[MediaType.avatar] = url;
            debugPrint('✅ [MediaService] Avatar URL: $url');
          }
          if (url.contains('voice')) {
            urls[MediaType.voice] = url;
            debugPrint('✅ [MediaService] Voice URL: $url');
          }
        }
      } else {
        debugPrint('⚠️ [MediaService] No URLs en la respuesta del backend');
      }

      debugPrint(
        '✅ [MediaService] Archivos asociados correctamente via backend',
      );
      debugPrint('✅ [MediaService] URLs finales: $urls');
      return urls;
    } catch (e) {
      debugPrint('❌ [MediaService] Error en associateMediaToUid: $e');
      rethrow;
    }
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
      request.fields['user_id'] = uid; // ahora usamos UID

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
