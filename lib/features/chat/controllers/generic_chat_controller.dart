import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';

/// Controlador genérico para chats
/// Puede ser extendido para diferentes implementaciones (IA, usuarios, etc.)
class GenericChatController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  bool _isActive = true;
  bool get isActive => _isActive;

  // 🆕 Flag para controlar auto-scroll
  bool _enableAutoScroll = true;
  bool get enableAutoScroll => _enableAutoScroll;

  /// 🆕 Permitir deshabilitar el auto-scroll desde el screen
  void setAutoScroll(bool enabled) {
    _enableAutoScroll = enabled;
  }

  /// Agregar un mensaje al chat
  void addMessage(Map<String, dynamic> message) {
    if (!_isActive) return;
    _messages.add(message);
    notifyListeners();

    // 🔒 Solo hacer auto-scroll si está habilitado
    if (_enableAutoScroll) {
      _scrollToBottom();
    }
  }

  /// Agregar múltiples mensajes
  void addMessages(List<Map<String, dynamic>> messages) {
    if (!_isActive) return;
    _messages.addAll(messages);
    notifyListeners();

    // 🔒 Solo hacer auto-scroll si está habilitado
    if (_enableAutoScroll) {
      _scrollToBottom();
    }
  }

  /// Enviar mensaje de texto del usuario
  Future<void> sendTextMessage(String text, {String? userId}) async {
    if (!_isActive || text.trim().isEmpty) return;

    addMessage({
      "other": false,
      "type": MessageType.text,
      "text": text,
      "time": getTimeNow(),
      "sentAt": DateTime.now(),
      "userId": userId,
    });

    // Este método puede ser sobrescrito en clases hijas
    await onMessageSent(text);
  }

  /// Callback que se ejecuta después de enviar un mensaje
  /// Puede ser sobrescrito en clases hijas para manejar la lógica específica
  Future<void> onMessageSent(String message) async {
    // Implementación base vacía
  }

  /// Agregar mensaje del otro participante
  void addOtherMessage({
    required String text,
    String name = "Usuario",
    String? userId,
  }) {
    if (!_isActive) return;

    addMessage({
      "other": true,
      "type": MessageType.text,
      "text": text,
      "name": name,
      "time": getTimeNow(),
      "userId": userId,
    });
  }

  /// Mostrar indicador de escritura
  void showTypingIndicator({String name = "Usuario"}) {
    if (!_isActive) return;

    addMessage({
      "other": true,
      "type": MessageType.typing,
      "name": name,
      "time": getTimeNow(),
    });
  }

  /// Remover indicador de escritura
  void removeTypingIndicator() {
    if (!_isActive) return;
    _messages.removeWhere((msg) => msg["type"] == MessageType.typing);
    notifyListeners();
  }

  /// Limpiar todos los mensajes
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Terminar el chat
  void terminateChat() {
    _isActive = false;
    notifyListeners();
  }

  /// Reactivar el chat
  void reactivateChat() {
    _isActive = true;
    notifyListeners();
  }

  /// Scroll automático al final (para ListView con reverse: true, ir al inicio)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isActive) return;
      if (scrollController.hasClients) {
        // Con reverse: true, los mensajes nuevos están en position 0
        scrollController.animateTo(
          0, // Ir al inicio (que visualmente es abajo con reverse: true)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _isActive = false;
    scrollController.dispose();
    super.dispose();
  }
}
