import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/utils/camera_permission_handler.dart';

class ChatAttachmentGrid extends StatelessWidget {
  final void Function(String path) onSendImage;
  const ChatAttachmentGrid({super.key, required this.onSendImage});

  Future<void> openGallery(BuildContext context) async {
    final imagePath = await CameraPermissionHandler.openGallery(
      imageQuality: 85,
      context: context,
    );

    if (imagePath != null) {
      onSendImage(imagePath);
    }
  }

  Future<void> openCamera(BuildContext context) async {
    final photoPath = await CameraPermissionHandler.openCamera(
      imageQuality: 85,
      context: context,
    );

    if (photoPath != null) {
      onSendImage(photoPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.8,
          children: [
            _buildAttachmentOption(
              context,
              icon: Icons.image_outlined,
              label: "chat.attachments.gallery".tr(),
              color: Colors.blue,
              onTap: () async => await openGallery(context),
            ),
            _buildAttachmentOption(
              context,
              icon: Icons.camera_alt_outlined,
              label: "chat.attachments.camera".tr(),
              color: Colors.pink,
              onTap: () async => await openCamera(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
