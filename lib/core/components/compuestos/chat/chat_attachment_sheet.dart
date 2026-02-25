import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:migozz_app/core/utils/camera_permission_handler.dart';
import 'package:migozz_app/core/components/compuestos/camera_view.dart';
import 'package:migozz_app/core/utils/web_file_picker_stub.dart'
    if (dart.library.html) 'package:migozz_app/core/utils/web_file_picker_web.dart';

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
    final photoPath = await showDialog<String?>(
      context: context,
      builder: (context) => const CameraView(),
    );
    if (photoPath != null) {
      onSendImage(photoPath);
    }
  }

  Future<void> openDocument(BuildContext context) async {
    try {
      if (kIsWeb) {
        final pathOrName = await pickDocumentWeb();
        if (pathOrName != null) {
          onSendImage(pathOrName);
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );
      if (result != null) {
        final pathOrName = result.files.single.path ?? result.files.single.name;
        onSendImage(pathOrName);
      }
    } catch (e) {
      debugPrint('Error en openDocument: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir documentos. ($e)')),
      );
    }
  }

  Future<void> openVideo(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        onSendImage(video.path);
      }
    } catch (e) {
      debugPrint('Error en openVideo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir el video: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
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
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 15,
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
              _buildAttachmentOption(
                context,
                icon: Icons.description_outlined,
                label: "Documentos",
                color: Colors.purple,
                onTap: () async => await openDocument(context),
              ),
              _buildAttachmentOption(
                context,
                icon: Icons.videocam_outlined,
                label: "Vídeo",
                color: Colors.orange,
                onTap: () async => await openVideo(context),
              ),
            ],
          ),
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
      child: SizedBox(
        width: 70,
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
