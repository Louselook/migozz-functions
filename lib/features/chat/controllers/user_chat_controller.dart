import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/chat/controllers/generic_chat_controller.dart';

/// Controlador para chat entre usuarios
/// Extiende GenericChatController y agrega funcionalidad específica para chats P2P
class UserChatController extends GenericChatController {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  // Callback para enviar mensajes al backend/Firebase
  final Future<void> Function(String message)? onSendToBackend;

  // Callback para marcar mensajes como leídos
  final Future<void> Function(String messageId)? onMarkAsRead;

  UserChatController({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.onSendToBackend,
    this.onMarkAsRead,
  });

  /// Cargar mensajes iniciales (ej: desde Firebase)
  void loadInitialMessages(List<Map<String, dynamic>> messages) {
    clearMessages();
    addMessages(messages);
  }

  /// Recibir un mensaje del otro usuario (ej: desde Firebase listener)
  void receiveMessage({
    required String text,
    required String messageId,
    DateTime? timestamp,
  }) {
    if (!isActive) return;

    addMessage({
      "other": true,
      "type": MessageType.text,
      "text": text,
      "name": otherUserName,
      "time": timestamp?.toString() ?? getTimeNow(),
      "messageId": messageId,
      "userId": otherUserId,
      "avatarUrl": otherUserAvatar,
    });

    // Marcar como leído si hay callback
    onMarkAsRead?.call(messageId);
  }

  /// Sobrescribir el método de envío para incluir lógica de backend
  @override
  Future<void> onMessageSent(String message) async {
    try {
      // Mostrar indicador de "enviando"
      debugPrint('📤 [UserChat] Enviando mensaje a $otherUserName');

      // Enviar al backend/Firebase
      if (onSendToBackend != null) {
        await onSendToBackend!(message);
        debugPrint('✅ [UserChat] Mensaje enviado exitosamente');
      } else {
        debugPrint('⚠️ [UserChat] No hay backend configurado');
      }
    } catch (e) {
      debugPrint('❌ [UserChat] Error al enviar mensaje: $e');
      // Aquí podrías agregar lógica para reintentar o mostrar error
    }
  }

  /// Enviar mensaje con imagen (para futuro)
  Future<void> sendImageMessage(String imagePath) async {
    if (!isActive) return;

    addMessage({
      "other": false,
      "type": MessageType.pictureCard,
      "pictures": [
        {"imageUrl": imagePath, "label": "Imagen"},
      ],
      "time": getTimeNow(),
      "userId": currentUserId,
    });

    // Aquí iría la lógica para subir la imagen y enviarla
    debugPrint('📸 [UserChat] Imagen enviada: $imagePath');
  }

  /// Enviar mensaje de audio (para futuro)
  Future<void> sendAudioMessage(String audioPath) async {
    if (!isActive) return;

    addMessage({
      "other": false,
      "type": MessageType.audio,
      "audio": audioPath,
      "time": getTimeNow(),
      "userId": currentUserId,
    });

    // Aquí iría la lógica para subir el audio y enviarlo
    debugPrint('🎤 [UserChat] Audio enviado: $audioPath');
  }

  /// Mostrar que el otro usuario está escribiendo
  void showOtherUserTyping() {
    showTypingIndicator(name: otherUserName);
  }

  /// Ocultar indicador de escritura del otro usuario
  void hideOtherUserTyping() {
    removeTypingIndicator();
  }
}
