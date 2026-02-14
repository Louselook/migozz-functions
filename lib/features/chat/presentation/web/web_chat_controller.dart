import 'package:flutter/foundation.dart';

class WebChatController {
  static final WebChatController _instance = WebChatController._internal();
  factory WebChatController() => _instance;
  WebChatController._internal();

  final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  void toggle() {
    isOpenNotifier.value = !isOpenNotifier.value;
  }

  void open() {
    isOpenNotifier.value = true;
  }

  void close() {
    isOpenNotifier.value = false;
  }
}
