// lib/features/profile/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/ai_assistant.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
// import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0; // índice del tab seleccionado

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Altura del gradiente inferior
    final bottomGradientHeight = size.height * 0.22;
    // Separación del card desde el borde inferior
    final bottomPaddingForCard = size.height * 0.25;

    // Tamaño del botón (proporcional para distintas pantallas)
    final assistantSize = (size.width * 0.18).clamp(56.0, 88.0);

    // Posición inicial del asistente IA (esquina inferior derecha)
    final initialAssistantPosition = Offset(
      size.width - assistantSize - (size.width * 0.03),
      size.height - bottomPaddingForCard + (size.height * 0.03),
    );

    // Posición inicial del social rail (derecha, centro-superior)
    final initialSocialPosition = Offset(
      size.width - 65, // 65 (itemSize) + 16 (padding)
      size.height * 0.2, // Posición más alta
    );

    return Scaffold(
      body: BackgroundImage(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomGradientHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3 puntos verticales arriba a la izquierda
            Positioned(
              left: 0,
              top: 70,
              child: GestureDetector(
                onTap: () => context.go('/edit-profile'),
                child: Column(
                  children: [
                    Icon(
                      Icons.more_vert,
                      color: const Color(0xAAFFFFFF),
                      size: 60,
                    ),
                  ],
                ),
              ),
            ),

            // Botón asistente IA (draggable)
            AIAssistant(
              size: assistantSize,
              initialPosition: initialAssistantPosition,
              onTap: () {
                // Aquí implementarás la lógica para abrir el chat del asistente
                debugPrint('Asistente IA presionado');
              },
            ),

            // rail social (ahora draggable)
            DraggableSocialRail(
              initialPosition: initialSocialPosition,
              links: [
                SocialLink(
                  asset: 'assets/icons/social_networks/TikTok.png',
                  url: Uri.parse('https://www.tiktok.com/@johndoe'),
                ),
                SocialLink(
                  asset: 'assets/icons/social_networks/Instagram.png',
                  url: Uri.parse('https://www.instagram.com/johndoe'),
                ),
                SocialLink(
                  asset: 'assets/icons/social_networks/X.png',
                  url: Uri.parse('https://x.com/johndoe'),
                ),
                SocialLink(
                  asset: 'assets/icons/social_networks/Pinterest.png',
                  url: Uri.parse('https://www.pinterest.com/johndoe'),
                ),
              ],
              itemSize: 50, // botón
              iconSize: 45, // icono dentro
            ),

            // zona del bottomnavigate
            Align(
              alignment: Alignment.bottomCenter,
              child: GradientBottomNav(
                currentIndex: _tab,
                onItemSelected: (i) => setState(() => _tab = i),
                onCenterTap: () async {
                  await FirebaseAuth.instance
                      .signOut(); // notificar a route para volver a login
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
