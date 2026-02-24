import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';

/// Widget individual para mostrar un chat en la lista (con badge de no leídos)
class ChatListItem extends StatelessWidget {
  final ChatPreview chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar con indicador de online
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: chat.avatarUrl != null
                      ? NetworkImage(chat.avatarUrl!)
                      : null,
                  onBackgroundImageError: chat.avatarUrl != null
                      ? (_, __) {}
                      : null,
                  child: chat.avatarUrl == null
                      ? Text(
                          chat.displayName.isNotEmpty
                              ? chat.displayName[0].toUpperCase()
                              : chat.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Indicador de online
                if (chat.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1C1C1E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Información del chat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          chat.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight
                                      .w700 // Bold si hay no leídos
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 🆕 Icono de bloqueado
                      if (chat.isBlocked)
                        const Icon(Icons.block, color: Colors.red, size: 14),
                      // Badge de verificado
                      if (chat.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF00D4FF),
                          size: 16,
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Último mensaje y tiempo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            color: chat.unreadCount > 0
                                ? Colors
                                      .white // Más visible si hay no leídos
                                : Colors.grey[500],
                            fontSize: 14,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight
                                      .w600 // Bold si hay no leídos
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chat.timeAgo,
                        style: TextStyle(
                          color: chat.unreadCount > 0
                              ? const Color(
                                  0xFF00D4FF,
                                ) // Destacar si hay no leídos
                              : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Badge de mensajes no leídos o botón de cámara
            if (chat.unreadCount > 0)
              // Badge de no leídos
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                child: Center(
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // else
            //   // Botón de cámara (solo si no hay no leídos)
            //   Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.grey[900],
            //       shape: BoxShape.circle,
            //     ),
            //     child: Icon(
            //       Icons.camera_alt,
            //       color: Colors.grey[400],
            //       size: 20,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
