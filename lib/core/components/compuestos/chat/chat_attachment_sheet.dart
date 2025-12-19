import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/color.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatAttachmentGrid extends StatelessWidget {
  final void Function(String path) onSendImage;
  const ChatAttachmentGrid({super.key, required this.onSendImage});

  Future<void> openGallery() async {
    // Para Android 13+ (API 33+) usa READ_MEDIA_IMAGES
    // Para versiones anteriores usa READ_EXTERNAL_STORAGE
    PermissionStatus status;

    if (await Permission.photos.isGranted) {
      status = PermissionStatus.granted;
    } else {
      // Intenta con photos primero (Android 13+)
      status = await Permission.photos.request();

      // Si no funciona, intenta con storage (Android < 13)
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
    }

    if (status.isGranted) {
      try {
        final XFile? image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (image != null) {
          onSendImage(image.path);
          debugPrint('✅ Imagen seleccionada: ${image.path}');
        } else {
          debugPrint('⚠️ No se seleccionó ninguna imagen');
        }
      } catch (e) {
        debugPrint('❌ Error al abrir galería: $e');
      }
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Permiso denegado permanentemente');
      // Opcional: mostrar diálogo para abrir configuración
      await openAppSettings();
    } else {
      debugPrint('⚠️ Permiso de galería denegado');
    }
  }

  Future<void> openCamera() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        final XFile? photo = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (photo != null) {
          onSendImage(photo.path);
          debugPrint('✅ Foto capturada: ${photo.path}');
        } else {
          debugPrint('⚠️ No se capturó ninguna foto');
        }
      } catch (e) {
        debugPrint('❌ Error al abrir cámara: $e');
      }
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Permiso de cámara denegado permanentemente');
      await openAppSettings();
    } else {
      debugPrint('⚠️ Permiso de cámara denegado');
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
              onTap: () async => await openGallery(),
            ),
            _buildAttachmentOption(
              context,
              icon: Icons.camera_alt_outlined,
              label: "chat.attachments.camera".tr(),
              color: Colors.pink,
              onTap: () async => await openCamera(),
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
