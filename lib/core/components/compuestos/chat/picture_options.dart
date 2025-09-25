import 'dart:io';
import 'package:flutter/material.dart';

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

    // 🔹 Una sola imagen
    if (pictures.length == 1) {
      final pic = pictures.first;
      return Column(
        crossAxisAlignment: sender
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,

        children: [
          GestureDetector(
            onTap: () => _showImagePopup(context, pic["imageUrl"]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(pic["imageUrl"], width: 80, height: 80),
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
    }

    // 🔹 Varias imágenes
    return Column(
      crossAxisAlignment: sender
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pictures.map((pic) {
            return GestureDetector(
              onTap: () => _showImagePopup(context, pic["imageUrl"]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(pic["imageUrl"], width: 80, height: 80),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // 🔹 Imagen (URL o local)
  Widget _buildImage(
    String? path, {
    required double width,
    required double height,
  }) {
    if (path == null) {
      return Container(color: Colors.grey, width: width, height: height);
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  // 🔹 Mostrar imagen grande con animación tipo popup
  void _showImagePopup(BuildContext context, String? path) {
    if (path == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: path.startsWith('http')
                ? Image.network(path, fit: BoxFit.contain)
                : Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(scale: anim, child: child);
      },
    );
  }
}
