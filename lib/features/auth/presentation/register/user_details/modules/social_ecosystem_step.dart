import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/button_social.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';

class SocialEcosystemStep extends StatelessWidget {
  final PageController controller;
  const SocialEcosystemStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Lista original
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

    // Label -> path exacto
    final Map<String, String> iconByLabel = {
      "Tiktok": "assets/icons/social_networks/TikTok.svg",
      "Instagram": "assets/icons/social_networks/Instagram.svg",
      "Facebook": "assets/icons/social_networks/Facebook.svg",
      "Youtube": "assets/icons/social_networks/Youtube.svg",
      "Telegram": "assets/icons/social_networks/Telegram.svg",
      "Whatsapp": "assets/icons/social_networks/WhatsApp.svg",
      "Pinterest": "assets/icons/social_networks/Pinterest.svg",
      "Spotify": "assets/icons/social_networks/Spotify.svg",
      "X": "assets/icons/social_networks/X.svg",
      "LinkedIn": "assets/icons/social_networks/LinkedIn.svg",
      "Paypal": "assets/icons/social_networks/Paypal.svg",
      "Xbox": "assets/icons/social_networks/Xbox.svg",
    };

    // Label -> tamaño personalizado para cada icono
    final Map<String, double> iconSizeByLabel = {
      "Tiktok": 38.0, // Un poco más grande para mayor visibilidad
      "Instagram": 36.0, // Tamaño estándar
      "Facebook": 35.0, // Ligeramente más pequeño
      "Youtube": 40.0, // Más grande para el play button
      "Telegram": 34.0, // Más compacto
      "Whatsapp": 37.0, // Buen tamaño para el logo
      "Pinterest": 35.0, // Estándar
      "Spotify": 36.0, // Para que se vea bien el círculo
      "X": 32.0, // Más pequeño, es un diseño minimalista
      "LinkedIn": 35.0, // Profesional, tamaño estándar
      "Paypal": 38.0, // Más grande para mejor legibilidad
      "Xbox": 39.0, // Un poco más grande para el logo
    };

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
                  final assetPath = iconByLabel[label];
                  final iconSize =
                      iconSizeByLabel[label] ??
                      35.0; // Tamaño personalizado o por defecto
                  return SocialIconCard(
                    label: label,
                    assetPath: assetPath,
                    iconSize:
                        iconSize, // Usa el tamaño personalizado para cada icono
                    onTap: () {
                      final cubit = context.read<RegisterCubit>();
                      final current = List<String>.from(
                        cubit.state.socialEcosystem ?? [],
                      );
                      if (!current.contains(label)) {
                        current.add(label);
                      } else {
                        current.remove(label); // toggle
                      }
                      cubit.setSocialEcosystem(current);
                      debugPrint(
                        "🌐 Ecosistema social: ${cubit.state.socialEcosystem}",
                      );
                    },
                  );
                },
              ),
            ),

            // Botones
            newButtonBack(controller: controller, context: context),
          ],
        ),
      ),
    );
  }
}
