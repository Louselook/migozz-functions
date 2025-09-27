import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/color.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatAttachmentGrid extends StatelessWidget {
  final void Function(String path) onSendImage;
  const ChatAttachmentGrid({super.key, required this.onSendImage});

  Future<void> openGallery() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // opcional para reducir tamaño
      );
      if (image != null) {
        onSendImage(image.path);
        debugPrint(image.path);
      }
    } else {
      debugPrint("Permiso de galería denegado");
    }
  }

  Future<void> openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        onSendImage(photo.path);
        debugPrint(photo.path);
      }
    } else {
      debugPrint("Permiso de cámara denegado");
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
              label: "Galería",
              color: Colors.blue,
              onTap: () async => await openGallery(),
            ),
            _buildAttachmentOption(
              context,
              icon: Icons.camera_alt_outlined,
              label: "Cámara",
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


            // _buildAttachmentOption(
            //   context,
            //   icon: Icons.headphones_outlined,
            //   label: "Audio",
            //   color: Colors.orange,
            //   onTap: () {
            //     // Lógica para enviar audio
            //   },
            // ),
// _buildAttachmentOption(
//               context,
//               icon: Icons.location_on_outlined,
//               label: "Ubicación",
//               color: Colors.green,
//               onTap: () {
//                 // Lógica para enviar ubicación
//               },
//             ),
//             _buildAttachmentOption(
//               context,
//               icon: Icons.person_outline,
//               label: "Contacto",
//               color: Colors.cyan,
//               onTap: () {
//                 // Lógica para enviar contacto
//               },
//             ),
//             _buildAttachmentOption(
//               context,
//               icon: Icons.description_outlined,
//               label: "Documento",
//               color: Colors.indigo,
//               onTap: () {
//                 // Lógica para documentos
//               },
//             ),

  // _buildAttachmentOption(
  //             context,
  //             icon: Icons.poll_outlined,
  //             label: "Encuesta",
  //             color: Colors.amber,
  //             onTap: () {
  //               // Lógica para encuesta
  //             },
  //           ),
  //           _buildAttachmentOption(
  //             context,
  //             icon: Icons.event_outlined,
  //             label: "Evento",
  //             color: Colors.deepPurple,
  //             onTap: () {
  //               // Lógica para crear evento
  //             },
  //           ),