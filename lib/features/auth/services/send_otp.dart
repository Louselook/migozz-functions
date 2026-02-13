import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:migozz_app/core/config/api/api_config.dart';

/// Sends OTP to the specified email
/// [email] - User's email address
/// [language] - Language code for the email ('en' or 'es'). Defaults to 'en'
Future<Map<String, dynamic>> sendOTP({
  required String email,
  String language = 'en',
  String? myOTP,
}) async {
  debugPrint("📧 Sending OTP to: $email (language: $language)");

  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBase}/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'language': language}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      myOTP = data['otp'];
      return {"sent": true, "myOTP": myOTP};
    }
  } catch (e) {
    debugPrint("❌ Error sending OTP: $e");
  }

  return {"sent": false, "myOTP": null};
}
