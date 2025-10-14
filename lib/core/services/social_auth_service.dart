import 'dart:async';
import 'package:flutter/services.dart';

class SocialAuthService {
  SocialAuthService._private();
  static final SocialAuthService _instance = SocialAuthService._private();
  factory SocialAuthService() => _instance;

  final MethodChannel _channel = const MethodChannel('socialAuth');
  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// Registra el handler del channel una sola vez.
  void init() {
    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments is Map)
          ? Map<String, dynamic>.from(call.arguments)
          : {"value": call.arguments};
      _controller.add({"method": call.method, "args": args});
    });
  }

  void dispose() {
    _controller.close();
  }
}
