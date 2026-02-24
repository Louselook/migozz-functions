import 'dart:io';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class PictureOptions extends StatelessWidget {
  final List<Map<String, String>> pictures;
  final String time;
  final bool sender;
  final String? senderName;
  final String? senderAvatar;

  const PictureOptions({
    super.key,
    required this.pictures,
    required this.time,
    this.sender = false,
    this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) return const SizedBox.shrink();

    // sender=true significa que el OTRO lo envió (izquierda, gris)
    // sender=false significa que YO lo envié (derecha, con gradiente)

    return Align(
      alignment: sender ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300, // límite opcional (como WhatsApp)
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: sender ? Colors.grey[900] : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: sender
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              if (sender) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderAvatar != null && senderAvatar!.isNotEmpty)
                      CircleAvatar(
                        radius: 9,
                        backgroundImage: NetworkImage(senderAvatar!),
                        onBackgroundImageError: (_, __) {},
                      )
                    else if (senderName != null && senderName!.isNotEmpty)
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          senderName![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      senderName ?? "Usuario",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (pictures.length == 1)
                _buildSingleImage(pictures.first)
              else
                _buildMultipleImages(),

              const SizedBox(height: 8),

              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(Map<String, String> pic) {
    return _FramedImage(
      imagePath: pic["imageUrl"],
      width: 210,
      height: 140,
      isFromOther: sender,
      onTap: () {},
    );
  }

  Widget _buildMultipleImages() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: sender ? WrapAlignment.start : WrapAlignment.end,
      children: pictures.map((pic) {
        return _FramedImage(
          imagePath: pic["imageUrl"],
          width: 140,
          height: 100,
          isFromOther: sender,
          onTap: () {},
        );
      }).toList(),
    );
  }
}

/// Marco para imagen con estilo diferente según quién la envió
class _FramedImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final bool isFromOther;
  final VoidCallback? onTap;

  const _FramedImage({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.isFromOther,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePopup(context, imagePath),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          // Gradiente si es MÍO, gris si es del OTRO
          gradient: isFromOther
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient.colors,
                ),
          color: isFromOther ? Colors.grey[700] : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: width,
            height: height,
            child: _buildImage(imagePath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? path, {BoxFit fit = BoxFit.cover}) {
    if (path == null || path.isEmpty) {
      return const Icon(Icons.image, color: Colors.white54, size: 40);
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFFDF48A5),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 40,
          );
        },
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.white54, size: 40);
      },
    );
  }

  void _showImagePopup(BuildContext context, String? path) {
    if (path == null || path.isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          child: Center(
            child: InteractiveViewer(
              child: path.startsWith('http')
                  ? Image.network(path, fit: BoxFit.contain)
                  : Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}
