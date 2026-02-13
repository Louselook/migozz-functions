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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con avatar y nombre (solo si showHeader es true)
          if (showHeader) ...[
            Row(
              children: [
                // Avatar personalizado o logo de Migozz
                if (hasCustomAvatar)
                  CircleAvatar(
                    radius: 9,
                    backgroundImage: NetworkImage(otherUserAvatar!),
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
                  Image.asset("assets/images/Migozz.webp", width: 18, height: 18),

                const SizedBox(width: 6),

                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Texto del mensaje
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),

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
    );
  }
}
