import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/config/api/api_config.dart';

/// Model for pre-register data
class PreRegisterData {
  final bool isPreRegistered;
  final String? preOrderId;
  final String? email;
  final String? username;

  PreRegisterData({
    required this.isPreRegistered,
    this.preOrderId,
    this.email,
    this.username,
  });

  factory PreRegisterData.fromJson(Map<String, dynamic> json) {
    return PreRegisterData(
      isPreRegistered: json['isPreRegistered'] ?? false,
      preOrderId: json['preOrderId'],
      email: json['email'],
      username: json['username'],
    );
  }

  factory PreRegisterData.notFound() {
    return PreRegisterData(isPreRegistered: false);
  }
}

/// Service for handling pre-registration logic
class PreRegisterService {
  final String? _baseUrl = ApiConfig.apiBase;

  /// Check if an email is pre-registered and get the reserved username
  Future<PreRegisterData> getPreRegisterByEmail(String email) async {
    if (_baseUrl == null) {
      debugPrint('❌ [PreRegisterService] API_MIGOZZ not configured');
      return PreRegisterData.notFound();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/get-preregister'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [PreRegisterService] Response: $data');

        if (data['found'] == true && data['isPreRegistered'] == true) {
          return PreRegisterData(
            isPreRegistered: true,
            preOrderId: data['preOrderId'],
            email: data['email'],
            username: data['username'],
          );
        }
      }

      return PreRegisterData.notFound();
    } catch (e) {
      debugPrint('❌ [PreRegisterService] Error checking pre-register: $e');
      return PreRegisterData.notFound();
    }
  }

  /// Delete a pre-order document after successful registration
  Future<bool> deletePreOrder(String preOrderId) async {
    if (_baseUrl == null) {
      debugPrint('❌ [PreRegisterService] API_MIGOZZ not configured');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/delete-preorder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'preOrderId': preOrderId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [PreRegisterService] Pre-order deleted: $data');
        return data['success'] == true;
      }

      debugPrint(
        '⚠️ [PreRegisterService] Failed to delete pre-order: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [PreRegisterService] Error deleting pre-order: $e');
      return false;
    }
  }

  /// Migrate a pre-order document to the new Firebase Auth UID
  /// This replaces the old delete flow - instead of deleting, we migrate
  Future<bool> migratePreOrder({
    required String preOrderId,
    required String newUid,
    Map<String, dynamic>? userData,
  }) async {
    if (_baseUrl == null) {
      debugPrint('❌ [PreRegisterService] API_MIGOZZ not configured');
      return false;
    }

    try {
      debugPrint(
        '🔄 [PreRegisterService] Migrating pre-order $preOrderId to UID $newUid',
      );

      final body = <String, dynamic>{
        'preOrderId': preOrderId,
        'newUid': newUid,
        if (userData != null) 'userData': userData,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/pre-register/migrate-preorder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [PreRegisterService] Pre-order migrated: $data');
        return data['success'] == true;
      }

      debugPrint(
        '⚠️ [PreRegisterService] Failed to migrate pre-order: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [PreRegisterService] Error migrating pre-order: $e');
      return false;
    }
  }
}
