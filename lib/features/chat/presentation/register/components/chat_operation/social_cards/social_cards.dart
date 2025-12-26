import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';

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
    final items = {
      "Followers": platformData["followers"],
      "Following": platformData["following"],
      "Likes": platformData["likes_count"],
      "Content": platformData["mediaCount"],
      "Views": platformData["viewCount"],
    };

    // Filtra los que no tienen valor
    final validItems = items.entries.where((e) {
      final v = e.value;
      return v != null && v.toString().trim().isNotEmpty && v != 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: validItems
          .map((e) => customCardTeext("${e.key}: ${e.value}"))
          .toList(),
    );
  }

  Widget customCardTeext(String text) {
    return Text(
      text,
      style: TextStyle(color: AppColors.backgroundLight, fontSize: 10),
    );
  }
}
