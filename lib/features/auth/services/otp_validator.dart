import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// srvicio propio
Future<PasswordChangeResult> changePassword({
  required String email,
  required String newPassword,
}) async {
  // url localhost
  final url = Uri.parse('http://10.0.2.2:8000/change-password');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'new_password': newPassword.trim(),
      }),
    );

    if (response.statusCode == 200) {
      // Cambiar contraseña OK, iniciar sesión automáticamente
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: newPassword.trim(),
      );

      return PasswordChangeResult(success: true);
    } else {
      final error = jsonDecode(response.body)['detail'];
      return PasswordChangeResult(success: false, message: error);
    }
  } catch (e) {
    return PasswordChangeResult(success: false, message: e.toString());
  }
}

// modelo de respusta
class PasswordChangeResult {
  final bool success;
  final String? message;

  PasswordChangeResult({required this.success, this.message});
}
