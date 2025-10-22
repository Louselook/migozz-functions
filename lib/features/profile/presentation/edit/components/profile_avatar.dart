import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onEdit;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.uploading,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.36;

    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Si hay error cargando, dejamos el fondo vacío
                      return Container(color: Colors.grey[900]);
                    },
                  )
                : Container(
                    color: Colors.grey[900],
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: uploading ? null : onEdit,
            child: CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              radius: 20,
              child: uploading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
