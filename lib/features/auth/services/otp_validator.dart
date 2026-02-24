import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/core/config/api/api_config.dart';

// Servicio propio
Future<PasswordChangeResult> changePassword({
  required String email,
  required String newPassword,
}) async {
  final url = Uri.parse('${ApiConfig.apiBase}/users/change-password');
  debugPrint('URL: $url');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'new_password': newPassword.trim(),
      }),
    );

    if (response.statusCode == 429) {
      return PasswordChangeResult(
        success: false,
        message: "Demasiadas solicitudes. Por favor espera unos minutos.",
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      return PasswordChangeResult(
        success: false,
        message: "Error del servidor: ${response.statusCode}",
      );
    }

    // Decodificar siempre la respuesta si no está vacía
    final data = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {"success": false, "message": "Respuesta vacía del servidor"};

    // Si el cambio de contraseña fue exitoso, hacer login automático
    if (data['success'] == true) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: newPassword.trim(),
      );
    }

    return PasswordChangeResult(
      success: data['success'] ?? false,
      message: data['message'] ?? 'Sin mensaje del servidor',
    );
  } catch (e) {
    return PasswordChangeResult(success: false, message: e.toString());
  }
}

// Modelo de respuesta
class PasswordChangeResult {
  final bool success;
  final String? message;

  PasswordChangeResult({required this.success, this.message});
}
