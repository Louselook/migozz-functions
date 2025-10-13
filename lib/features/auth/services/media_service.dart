import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// 🔹 Asociar archivos temporales (guardados con el email) al UID definitivo del usuario
  Future<Map<MediaType, String>> associateMediaToUid({
    required String uid,
    required String email,
  }) async {
    final storage = FirebaseStorage.instance;
    final urls = <MediaType, String>{};

    // carpetas que se manejan
    const folders = {
      MediaType.avatar: 'avatar',
      MediaType.voice: 'voice',
    };

    for (final entry in folders.entries) {
      final folder = entry.value;
      final oldRef = storage.ref().child('$folder/$email');
      final newRef = storage.ref().child('$folder/$uid');

      try {
        // Listar todos los archivos que haya en la carpeta (por si hay más de uno)
        final oldFiles = await oldRef.listAll();

        for (final item in oldFiles.items) {
          // descargamos los bytes
          final data = await item.getData();
          if (data == null) continue;

          // creamos el nuevo archivo con el mismo nombre
          final newFileRef = newRef.child(item.name);
          await newFileRef.putData(data);

          // borramos el archivo viejo
          await item.delete();

          // obtenemos la nueva URL pública
          final newUrl = await newFileRef.getDownloadURL();
          urls[entry.key] = newUrl;
        }
      } catch (e) {
        // si no existía esa carpeta o no había archivo, simplemente se ignora
        debugPrint('No se pudo mover archivo de $folder/$email → $folder/$uid: $e');
      }
    }

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

