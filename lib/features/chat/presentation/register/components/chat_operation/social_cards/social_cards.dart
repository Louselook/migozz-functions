import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';

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
          width: 200, // ancho fijo
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (iconPath.isNotEmpty)
                  iconPath.endsWith('.svg')
                      ? SvgPicture.asset(iconPath, width: 40, height: 40)
                      : Image.asset(iconPath, width: 40, height: 40),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (followers != null) ...[
                      const SizedBox(height: 4),
                      dataCard(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dataCard() {
    // Definir campos prioritarios por red social (en orden de relevancia)
    final priorityMap = {
      'tiktok': ['followers', 'likes', 'videos'],
      'instagram': ['followers', 'mediaCount', 'following'],
      'youtube': ['followers', 'viewCount', 'mediaCount'],
      'twitter': ['followers', 'likes_count', 'mediaCount'],
      'spotify': ['followers'],
      'facebook': ['followers'],
      'linkedin': ['followers', 'connections'],
      'twitch': ['followers'],
      'pinterest': ['followers', 'following'],
      'reddit': ['followers', 'karma'],
      'threads': ['followers', 'following'],
      'soundcloud': ['followers', 'track_count'],
      'kick': ['followers'],
      'trovo': ['followers'],
    };

    // Obtener la red social (del label o de los datos)
    final label = platformData["label"]?.toString().toLowerCase() ?? "";
    final platformType = label.replaceAll(' ', '').toLowerCase();

    // Obtener campos a mostrar (máximo 2 para mantener diseño limpio)
    List<String> fieldsToShow = [];
    final priorityFields = priorityMap[platformType] ?? [];

    for (final field in priorityFields) {
      if (platformData.containsKey(field) &&
          platformData[field] != null &&
          platformData[field] != 0) {
        fieldsToShow.add(field);
        if (fieldsToShow.length >= 2) break;
      }
    }

    // Si no hay campos prioritarios, buscar el primero disponible
    if (fieldsToShow.isEmpty) {
      final metricsFields = [
        'followers',
        'following',
        'likes',
        'likes_count',
        'mediaCount',
        'viewCount',
        'videos',
        'karma',
        'connections',
        'track_count',
      ];
      for (final field in metricsFields) {
        if (platformData.containsKey(field) &&
            platformData[field] != null &&
            platformData[field] != 0) {
          fieldsToShow.add(field);
          if (fieldsToShow.length >= 2) break;
        }
      }
    }

    // Construir los datos a mostrar
    final displayItems = fieldsToShow.map((field) {
      final value = platformData[field];
      final displayLabel = _formatFieldLabel(field);
      return "$displayLabel: ${formatNumber(value)}";
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayItems.map((text) => customCardText(text)).toList(),
    );
  }

  /// Formatea nombres de campos de manera legible
  String _formatFieldLabel(String field) {
    const labelMap = {
      'followers': 'Followers',
      'following': 'Following',
      'likes': 'Likes',
      'likes_count': 'Likes',
      'mediaCount': 'Content',
      'videos': 'Videos',
      'viewCount': 'Views',
      'connections': 'Connections',
      'track_count': 'Tracks',
      'karma': 'Karma',
    };
    return labelMap[field] ?? field;
  }

  Widget customCardText(String text) {
    return Text(
      text,
      style: TextStyle(color: AppColors.backgroundLight, fontSize: 10),
    );
  }
}
