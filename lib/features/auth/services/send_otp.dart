import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:migozz_app/core/config/api/api_config.dart';

Future<Map<String, dynamic>> sendOTP({
  required String email,
  String? myOTP,
}) async {
  debugPrint("correo: $email");

  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBase}/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      myOTP = data['otp'];
      return {"sent": true, "myOTP": myOTP};
    }
  } catch (e) {
    debugPrint("Error: $e");
  }

  return {"sent": false, "myOTP": null};
}
