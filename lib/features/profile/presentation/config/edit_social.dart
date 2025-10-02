import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_detail_step.dart';

class EditSocialScreen extends StatelessWidget {
  const EditSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleFactor = context.scaleFactor;

    // Lista de redes
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
      "Other",
    ];

    // Label -> assetPath // recomiendo llamar directamente cada app registrada en el cubit por temas de seleccion
    final Map<String, String> iconByLabel = {
      "Tiktok": "assets/icons/social_networks/TikTok.png",
      "Instagram": "assets/icons/social_networks/Instagram.png",
      "Facebook": "assets/icons/social_networks/Facebook.png",
      "Youtube": "assets/icons/social_networks/Youtube.png",
      "Telegram": "assets/icons/social_networks/Telegram.png",
      "Whatsapp": "assets/icons/social_networks/WhatsApp.png",
      "Pinterest": "assets/icons/social_networks/Pinterest.png",
      "Spotify": "assets/icons/social_networks/Spotify.png",
      "X": "assets/icons/social_networks/X.png",
      "LinkedIn": "assets/icons/social_networks/LinkedIn.png",
      "Paypal": "assets/icons/social_networks/Paypal.svg",
      "Xbox": "assets/icons/social_networks/Xbox.svg",
      "Other": "assets/icons/social_networks/Other.png",
    };

    // Responsive paddings
    final horizontalPadding = ResponsiveUtils.scaleValue(
      20.0, scaleFactor,
      minValue: 16.0,
      maxValue: 28.0,
    );
    final topSpacing = ResponsiveUtils.scaleValue(
      16.0, scaleFactor,
      minValue: 12.0,
      maxValue: 24.0,
    );

    final crossAxisCount = 3; // fijo para que quede igual a la maqueta
    final crossAxisSpacing = 16.0;
    final mainAxisSpacing = 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Edit Socials",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: topSpacing),
            const SecondaryText("Add your platforms"),
            SizedBox(height: topSpacing),

            // Grid con íconos
            Expanded(
              child: GridView.builder(
                itemCount: socials.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: 1, // cuadrado
                ),
                itemBuilder: (context, index) {
                  final label = socials[index];
                  final assetPath = iconByLabel[label] ?? "";

                  return SocialIconCard(
                    label: label,
                    assetPath: assetPath,
                    isSelected: false, // manejar luego con cubit o estado
                    onTap: () async {
                      // Solo navegar a SocialDetailScreen si la opción es "Other"
                      if (label == "Other") {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SocialDetailScreen(
                              label: label,
                              assetPath: assetPath,
                            ),
                          ),
                        );
                      } else {
                        // Para otras redes sociales, puedes agregar lógica diferente aquí
                        // Por ejemplo, seleccionar/deseleccionar o abrir un editor específico
                        debugPrint("Selected: $label");
                      }
                    },
                  );
                },
              ),
            ),

            // Botón Save
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C3B), Color(0xFF9D1FFF)],
                ),
              ),
              child: TextButton(
                onPressed: () {
                  // Guardar cambios
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
