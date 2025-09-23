import 'package:flutter/material.dart';

class PictureOptions extends StatelessWidget {
  final List<Map<String, String>> pictures;
  final String time;

  const PictureOptions({super.key, required this.pictures, required this.time});

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) {
      return const SizedBox.shrink();
    }

    // 📌 Caso 1: una sola imagen → imagen grande como mensaje normal
    if (pictures.length == 1) {
      final pic = pictures.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // cargar imagenes de la web
            child: Image.network(
              pic["imageUrl"] ?? "",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
    }

    // 📌 Caso 2: varias imágenes → grid de círculos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pictures.map((pic) {
            return GestureDetector(
              onTap: () {
                debugPrint("Clicked on ${pic['label']}");
              },
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: pic["imageUrl"] != null
                    ? NetworkImage(pic["imageUrl"]!)
                    : null,
                child: pic["imageUrl"] == null
                    ? Icon(Icons.person, size: 32, color: Colors.grey.shade600)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
