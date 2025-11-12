import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/chat/controllers/user_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/components/generic_chat_screen.dart';

/// Pantalla de chat entre dos usuarios
class UserChatScreen extends StatefulWidget {
  final UserDTO otherUser;
  final String currentUserId;

  const UserChatScreen({
    super.key,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late UserChatController _chatController;

  @override
  void initState() {
    super.initState();

    _chatController = UserChatController(
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUser.email, // Usar email como ID por ahora
      otherUserName: widget.otherUser.displayName.isNotEmpty
          ? widget.otherUser.displayName
          : widget.otherUser.username,
      otherUserAvatar: widget.otherUser.avatarUrl,
      onSendToBackend: _sendMessageToBackend,
      onMarkAsRead: _markMessageAsRead,
    );

    // Cargar mensajes previos (simulado por ahora)
    _loadMessages();

    // TODO: Escuchar nuevos mensajes desde Firebase
    // _listenToMessages();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Simular carga de mensajes (reemplazar con Firebase)
  void _loadMessages() {
    // Por ahora vacío, aquí irían los mensajes desde Firebase
    debugPrint(
      '📥 [UserChat] Cargando mensajes con ${widget.otherUser.username}',
    );
  }

  /// Enviar mensaje al backend (Firebase/API)
  Future<void> _sendMessageToBackend(String message) async {
    // TODO: Implementar envío a Firebase/Backend
    debugPrint('📤 [UserChat] Enviar a backend: $message');

    // Simulación de delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Aquí iría:
    // await FirebaseService.sendMessage(
    //   from: widget.currentUserId,
    //   to: widget.otherUser.email,
    //   message: message,
    // );
  }

  /// Marcar mensaje como leído
  Future<void> _markMessageAsRead(String messageId) async {
    // TODO: Implementar en Firebase/Backend
    debugPrint('✅ [UserChat] Marcar como leído: $messageId');
  }

  @override
  Widget build(BuildContext context) {
    return GenericChatScreen(
      chatController: _chatController,
      customAppBar: _buildAppBar(),
      backgroundColor: AppColors.backgroundDark,
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar del otro usuario
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.otherUser.avatarUrl?.isNotEmpty == true
                ? NetworkImage(widget.otherUser.avatarUrl!)
                : null,
            backgroundColor: Colors.grey[800],
            child: widget.otherUser.avatarUrl?.isEmpty ?? true
                ? Text(
                    widget.otherUser.displayName.isNotEmpty
                        ? widget.otherUser.displayName[0].toUpperCase()
                        : widget.otherUser.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Nombre y estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherUser.displayName.isNotEmpty
                      ? widget.otherUser.displayName
                      : widget.otherUser.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Toca para ver perfil", // Aquí podría ir estado: "Online", "Visto hace X min"
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Menú de opciones
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // TODO: Navegar al perfil del usuario
                debugPrint('👤 Ver perfil de ${widget.otherUser.username}');
                break;
              case 'block':
                // TODO: Bloquear usuario
                debugPrint('🚫 Bloquear a ${widget.otherUser.username}');
                break;
              case 'report':
                // TODO: Reportar usuario
                debugPrint('⚠️ Reportar a ${widget.otherUser.username}');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Ver perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 12),
                  Text('Bloquear'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 20),
                  SizedBox(width: 12),
                  Text('Reportar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
