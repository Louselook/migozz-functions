import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';

/// Service that handles all landing page API calls.
/// Mirrors the endpoints used in the React LandingMigozz project.
class LandingService {
  static final String? _baseUrl = ApiConfig.apiBase;

  /// Checks if a username already exists via the API.
  /// POST /pre-register/check-username
  static Future<bool> checkUsernameExists(String username) async {
    if (_baseUrl == null) {
      debugPrint('❌ [LandingService] API_MIGOZZ not configured');
      throw Exception('API not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/check-username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('⚠️ [LandingService] Could not parse response JSON: $e');
      }

      if (!response.statusCode.toString().startsWith('2')) {
        // 409 Conflict often implies existence
        if (response.statusCode == 409) return true;
        throw Exception(
          data['message'] ??
              data['detail'] ??
              'Server Error: ${response.statusCode}',
        );
      }

      // Handle different possible response formats
      if (data['exists'] is bool) return data['exists'] as bool;
      if (data['isAvailable'] is bool) return !(data['isAvailable'] as bool);
      if (data['available'] is bool) return !(data['available'] as bool);
      if (data['status'] == 'taken' || data['result'] == 'exists') return true;

      // 200 OK means "Available"
      return false;
    } catch (error) {
      debugPrint('❌ [LandingService] Error checking username: $error');
      rethrow;
    }
  }

  /// Checks if an email already exists via the API.
  /// POST /pre-register/check-email
  static Future<bool> checkEmailExists(String email) async {
    if (_baseUrl == null) {
      debugPrint('❌ [LandingService] API_MIGOZZ not configured');
      throw Exception('API not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('⚠️ [LandingService] Could not parse response JSON: $e');
      }

      if (!response.statusCode.toString().startsWith('2')) {
        if (response.statusCode == 409) return true;
        throw Exception(
          data['message'] ??
              data['detail'] ??
              'Server Error: ${response.statusCode}',
        );
      }

      if (data['exists'] is bool) return data['exists'] as bool;
      if (data['isAvailable'] is bool) return !(data['isAvailable'] as bool);
      if (data['available'] is bool) return !(data['available'] as bool);
      if (data['status'] == 'taken' || data['result'] == 'exists') return true;

      return false;
    } catch (error) {
      debugPrint('❌ [LandingService] Error checking email: $error');
      rethrow;
    }
  }

  /// Pre-register a user with username and email.
  /// POST /pre-register/
  static Future<bool> preRegister({
    required String username,
    required String email,
    required String language,
  }) async {
    if (_baseUrl == null) {
      debugPrint('❌ [LandingService] API_MIGOZZ not configured');
      throw Exception('API not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'username': username.trim(),
          'language': language,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      // Try to parse error message from API
      Map<String, dynamic> errorData = {};
      try {
        errorData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      final errorMsg =
          errorData['detail'] ??
          errorData['message'] ??
          errorData['error'] ??
          'Server Error: ${response.statusCode}';
      throw Exception(errorMsg);
    } catch (error) {
      debugPrint('❌ [LandingService] Error pre-registering: $error');
      rethrow;
    }
  }
}
