import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialCardMini extends StatelessWidget {
  final Map<String, dynamic> platformData;

  const SocialCardMini({super.key, required this.platformData});

  @override
  Widget build(BuildContext context) {
    final label = platformData["label"] ?? "";
    final iconPath = platformData["iconPath"] ?? "";
    final followers = platformData["followersFormatted"] as String?;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (platformData["profile_image_url"] != null)
                      Image.network(
                        platformData["profile_image_url"]!,
                        width: 80,
                        height: 80,
                      ),

                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    ...platformData.entries
                        .where(
                          (e) =>
                              e.key != "label" &&
                              e.key != "iconPath" &&
                              e.key != "profile_image_url",
                        )
                        .map(
                          (e) => Text(
                            "${e.key}: ${e.value}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 120, // ancho fijo igual para todas
          height: 120, // altura fija igual para todas
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconPath.isNotEmpty)
                  iconPath.endsWith('.svg')
                      ? SvgPicture.asset(iconPath, width: 50, height: 50)
                      : Image.asset(iconPath, width: 50, height: 50),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                if (followers != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    followers,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
