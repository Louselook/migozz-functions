import 'dart:io';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class PictureOptions extends StatelessWidget {
  final List<Map<String, String>> pictures;
  final String time;
  final bool sender;

  const PictureOptions({
    super.key,
    required this.pictures,
    required this.time,
    this.sender = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) return const SizedBox.shrink();

    if (pictures.length == 1) {
      final pic = pictures.first;
      return Column(
        crossAxisAlignment: sender
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _FramedImage(
              imagePath: pic["imageUrl"],
              width: 210,
              height: 140,
              onTap: () => _showImagePopup(context, pic["imageUrl"]),
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: sender
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: pictures.map((pic) {
              return _FramedImage(
                imagePath: pic["imageUrl"],
                width: 140,
                height: 100,
                onTap: () => _showImagePopup(context, pic["imageUrl"]),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showImagePopup(BuildContext context, String? path) {
    if (path == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: path.startsWith('http')
                ? Image.network(path, fit: BoxFit.contain)
                : Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
  }
}

/// --------------------------------------------------------------
///  Widget: _FramedImage
///  - Marco con gradiente (magenta→morado→azul)
///  - Fondo oscuro redondeado
///  - Imagen completa dentro
///  - “Pernos” en esquinas
/// --------------------------------------------------------------
class _FramedImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _FramedImage({
    required this.imagePath,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final image = _buildImage(imagePath, fit: BoxFit.cover);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient.colors,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(width: width, height: height, child: image),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildImage(String? path, {BoxFit fit = BoxFit.cover}) {
    if (path == null) {
      return Container(color: Colors.grey.shade700);
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }
}
