import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/scroll_sheet.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  const BackgroundImage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Altura del gradiente inferior
    final bottomGradientHeight = size.height * 0.22;
    // Separación del card desde el borde inferior
    final bottomPaddingForCard = size.height * 0.15;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen base (un pelín más saturada)
        SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: size.height,
                    width: size.width,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        1.15, 0, 0, 0, 0, // R
                        0, 1.15, 0, 0, 0, // G
                        0, 0, 1.25, 0, 0, // B
                        0, 1, 1, 2, 0, // A
                      ]),
                      child: Image.asset(
                        "assets/images/profileBackground.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomPaddingForCard),
                        child: FractionallySizedBox(
                          widthFactor: 0.45,
                          heightFactor: 0.17,
                          child: InfoUserProfile(
                            name: 'John Doe',
                            displayName: '@johndoe',
                            comunityCount: '1M',
                            nameComunity: 'Community',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              buildProfileCards(
                context,
                count: 12,
                onTap: (i) {
                  debugPrint("Card $i tocada");
                },
              ),
            ],
          ),
        ),

        // Tinte morado superior izq (radial)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.9), // arriba-izquierda
                radius: 1.0,
                colors: [
                  const Color(0xFFB86BFF).withOpacity(0.45), // morado
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),

        // Gradiente dorado inferior, suave
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // un poco más alto para que el fade termine antes del borde
          height: bottomGradientHeight * 1.6,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  // mueve el centro por debajo y a la derecha para que no se vea el borde del círculo
                  center: const Alignment(0.9, 1.4),
                  // radio más contenido
                  radius: 1.2,
                  colors: [
                    const Color(0xFFF3C623).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  // el transparente alcanza ~75% del radio; lo que queda ya es transparente
                  stops: const [0.4, 0.75],
                ),
              ),
            ),
          ),
        ),

        // Contenido por encima del color
        child,
      ],
    );
  }
}
