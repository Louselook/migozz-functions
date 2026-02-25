import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/profile_picture_selector.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/social_cards/social_cards.dart';

class OtherMessage extends StatelessWidget {
  final String text;
  final String time;
  final List<Map<String, dynamic>>? platforms;
  final List<Map<String, String>>? profilePictures;
  final RegisterChatController? chatController;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool showHeader;

  const OtherMessage({
    super.key,
    required this.text,
    required this.time,
    this.platforms,
    this.profilePictures,
    this.chatController,
    this.otherUserName,
    this.otherUserAvatar,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlatforms = platforms != null && platforms!.isNotEmpty;
    final hasProfilePictures =
        profilePictures != null && profilePictures!.isNotEmpty;

    // Determinar nombre y avatar a mostrar
    final displayName = otherUserName ?? "Migozz";
    final hasCustomAvatar =
        otherUserAvatar != null && otherUserAvatar!.isNotEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75 > 500
              ? 500
              : MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF6C6C70), // Darker grey for other message
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4), // Pointed top left
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con avatar y nombre (solo si showHeader es true)
            if (showHeader) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar personalizado o logo de Migozz
                  if (hasCustomAvatar)
                    CircleAvatar(
                      radius: 9,
                      backgroundImage: NetworkImage(otherUserAvatar!),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: Colors.grey[800],
                    )
                  else if (otherUserName != null && otherUserName!.isNotEmpty)
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        otherUserName![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    // Fallback: logo de Migozz (para chat de IA)
                    Image.asset(
                      "assets/images/Migozz.webp",
                      width: 18,
                      height: 18,
                    ),

                  const SizedBox(width: 6),

                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Texto del mensaje
            Text(
              text,
              style: const TextStyle(
                color: Colors.black, // Dark text like the image
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Time stamp at the bottom right
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
              ),
            ],

            // Fotos de perfil (para selección de avatar)
            if (hasProfilePictures && chatController != null) ...[
              const SizedBox(height: 12),
              ProfilePictureSelector(
                pictures: profilePictures!,
                chatController: chatController!,
              ),
            ],

            // Social Cards (para otras cosas)
            if (hasPlatforms) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: platforms!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SocialCardMini(platformData: platforms![index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
