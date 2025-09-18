import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/register/user_details/components/down_buttons.dart';
import 'package:migozz_app/features/register/user_details/components/social_icon_card.dart';

class SocialEcosystemStep extends StatelessWidget {
  final PageController controller;
  const SocialEcosystemStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // lista de redes sociales
    final List<String> socials = [
      "Tiktok",
      "Instagram",
      "Facebook",
      "Youtube",
      "Telegram",
      "Whatsapp",
      "Pinterest",
      "Spotify",
      "X",
      "LinkedIn",
      "Paypal",
      "Xbox",
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText("Your Social Ecosystem"),
            const SecondaryText("Add your platforms"),
            const SizedBox(height: 20),

            // contenido
            Expanded(
              child: GridView.builder(
                itemCount: socials.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 20,
                ),
                itemBuilder: (context, index) {
                  final label = socials[index];
                  return SocialIconCard(
                    label: label,
                    // sin assets todavía, solo el texto
                    onTap: () {
                      debugPrint("Clicked on $label");
                    },
                  );
                },
              ),
            ),

            // Botones
            downButtons(controller: controller),
          ],
        ),
      ),
    );
  }
}
