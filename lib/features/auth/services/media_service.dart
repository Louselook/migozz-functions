import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:migozz_app/core/config/api/api_config.dart';

enum MediaType { avatar, voice, video, document }

class UserMediaService {
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

  /// ----------------------
  /// Asociar archivos al UID definitivo en backend
  /// ----------------------
  Future<void> associateMediaToUid({
    required String uid,
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.apiBase}/users/associate-media');
    final body = {'uid': uid, 'email': email};

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Error asociando media: ${response.body}');
    }
  }
}
