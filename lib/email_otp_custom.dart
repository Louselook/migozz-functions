import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

// Modificacion de ela dependencia No hay asociación entre email
// puedee servirnos solo para agregar al firebase como password dinamicamente
// no nos afeectatanto el verificador, no lo neecesitamos para iniciar sesion
// pero si para validar correos lo cual si no existe el correo no tiene forma de saber el codigo

// Acciones:
//  - Capturar el codigo para confirmar localmeente con el que ingrese el usuario
//  - Reelacionar con el correo
//  - Ajustes necesarios para firebase y logica interna

/// Tipo de OTP
enum OTPType { numeric, alpha, alphaNumeric }

/// Temas de Email (v1 a v6)
enum EmailTheme { v1, v2, v3, v4, v5, v6 }

/// Email OTP simplificado con soporte de tema
class EmailOTP {
  static String? _otpResponse;
  static String? _appName;
  static String? _appEmail;
  static int? _otpLength;
  static OTPType? _otpType;
  static int? _expiry;
  static EmailTheme? _emailTheme; // agregado

  EmailOTP() {
    _otpResponse = _getRandomOTP();
  }

  /// Configuración básica
  static void config({
    String? appName,
    String? appEmail,
    int? otpLength,
    OTPType? otpType,
    int? expiry,
    EmailTheme? emailTheme, // agregado
  }) {
    _appName = appName ?? "Email OTP";
    _appEmail = appEmail ?? "noreply@email-otp.rohitchouhan.com";
    _otpLength = otpLength ?? 6;
    _otpType = otpType ?? OTPType.numeric;
    _expiry = expiry ?? 0;
    _emailTheme = emailTheme ?? EmailTheme.v5; // default
  }

  /// Enviar OTP
  static Future<bool> sendOTP({required String email}) async {
    final String baseUrl = kIsWeb
        ? "https://corsproxy.io/?https://email-otp.rohitchouhan.com"
        : "https://email-otp.rohitchouhan.com";
    final Uri uri = Uri.parse("$baseUrl/v3");

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      'X-Flutter-Request': "true",
      'Access-Control-Allow-Origin': "*",
    };

    final Map<String, dynamic> body = {
      "app_name": _appName,
      "app_email": _appEmail,
      "user_email": email,
      "otp_length": _otpLength,
      "type": _otpType?.name,
      "expiry": _expiry,
      "theme": _emailTheme?.name, // agregado para el tema
    };

    try {
      final http.Response response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['status'] == true) {
        _otpResponse = responseJson['otp'];
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener OTP generado
  static String? getOTP() {
    return _otpResponse;
  }

  /// Verificar OTP
  static bool verifyOTP({required String otp}) {
    if (_otpResponse == otp) {
      _otpResponse = null; // limpiar OTP después de verificar
      return true;
    }
    return false;
  }

  /// Generar OTP aleatorio local (para fallback)
  static String _getRandomOTP() {
    return (Random().nextInt(900000) + 100000).toString();
  }
}
