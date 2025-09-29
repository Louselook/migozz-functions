import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/profile/components/ai_assistant.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/image_background.dart';
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
    final bottomPaddingForCard = size.height * 0.15;

    // Tamaño y posición del botón (proporcional para distintas pantallas)
    final assistantSize = (size.width * 0.18).clamp(56.0, 88.0);
    final assistantRight = size.width * 0.03;
    final assistantBottom = bottomPaddingForCard - size.height * 0.03;

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
              top: 30,
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

            // Botón asistente IA
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: assistantRight,
                    bottom: assistantBottom,
                  ),
                  child: AIAssistant(size: assistantSize, onTap: () {}),
                ),
              ),
            ),

            // rail social
            Align(
              alignment: const Alignment(
                1,
                -0.05,
              ), // derecha y ligeramente arriba del centro
              child: Padding(
                padding: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.02,
                ),
                child: SocialRail(
                  links: [
                    SocialLink(
                      asset: 'assets/icons/social_networks/TikTok.svg',
                      url: Uri.parse('https://www.tiktok.com/@johndoe'),
                    ),
                    SocialLink(
                      asset: 'assets/icons/social_networks/Instagram.svg',
                      url: Uri.parse('https://www.instagram.com/johndoe'),
                    ),
                    SocialLink(
                      asset: 'assets/icons/social_networks/X.svg',
                      url: Uri.parse('https://x.com/johndoe'),
                    ),
                    SocialLink(
                      asset: 'assets/icons/social_networks/Pinterest.svg',
                      url: Uri.parse('https://www.pinterest.com/johndoe'),
                    ),
                  ],
                  itemSize: 42, // botón
                  iconSize: 22, // icono dentro
                ),
              ),
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
