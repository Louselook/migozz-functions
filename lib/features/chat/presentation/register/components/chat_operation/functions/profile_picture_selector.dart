import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';

/// Widget to show clickable profile pictures
class ProfilePictureSelector extends StatelessWidget {
  final List<Map<String, String>> pictures;
  final RegisterChatController chatController; // controller to send selected avatar

  const ProfilePictureSelector({
    super.key,
    required this.pictures,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pictures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pic = pictures[index];
          return GestureDetector(
            onTap: () => _showPhotoPreview(context, pic),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.network(
                      pic["imageUrl"]!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pic["platform"] ?? "",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, Map<String, String> photo) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cancel',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return _PhotoPreviewDialog(
          photo: photo,
          onConfirm: () {
            Navigator.of(context).pop();
            _selectPhoto(context, photo);
          },
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _selectPhoto(BuildContext context, Map<String, String> photo) {
    // Send the selected photo to the controller
    chatController.sendAvatarPhoto(photo["imageUrl"]!);

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          // Confirmation.
          'register.validations.picConfirmation'.tr(),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Custom dialog for photo preview
class _PhotoPreviewDialog extends StatelessWidget {
  final Map<String, String> photo;
  final VoidCallback onConfirm;

  const _PhotoPreviewDialog({required this.photo, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large photo with gradient frame
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.primaryGradient.colors,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      photo["imageUrl"]!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Warning box: informs user about potential low resolution
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.notifications_none,
                        color: Colors.orange[200],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        // English warning message
                        'register.warnings.profilePic'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // "Use this photo" button
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient.colors,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGradient.colors.first
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'register.presentation.profilePic'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Platform name text
              Text(
                '@${photo['label'] ?? photo['platform'] ?? 'social network'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 16),

              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'buttons.cancel'.tr(),
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
