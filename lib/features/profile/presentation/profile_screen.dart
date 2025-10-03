// lib/features/profile/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Map<String, dynamic>? _userDoc;
  List<Map<String, String>> _userSocials = const [];
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Usamos 'test' porque AuthService actualmente guarda allí
      final docTest = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? data = docTest.data();
      if (data == null) {
        final docUsers = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        data = docUsers.data();
      }

      if (mounted) {
        setState(() {
          _userDoc = data;
          _isLoading = false; // Marcar como cargado
        });

        // Force rebuild para asegurar que la UI se actualice
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });

        final username = (data?['username'] as String?) ?? '';
        if (username.isNotEmpty) {
          _loadUserSocials(username);
        }
      }
    } catch (e) {
      debugPrint('❌ Error cargando usuario: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Marcar como cargado aunque haya error
        });
      }
    }
  }

  Future<void> _loadUserSocials(String username) async {
    final u = username.replaceFirst('@', '');
    try {
      final q = await FirebaseFirestore.instance
          .collection('userSocials')
          .where('userName', isEqualTo: u)
          .get();
      final list = q.docs
          .map((d) {
            final m = d.data();
            return {
              'provider': (m['provider'] ?? '').toString(),
              'url': (m['url'] ?? '').toString(),
            };
          })
          .where((e) => e['provider']!.isNotEmpty)
          .toList();
      if (mounted) setState(() => _userSocials = list);
    } catch (e) {
      debugPrint('Error cargando userSocials: $e');
    }
  }

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
    // Obtener datos reales del usuario
    final rawname = (_userDoc?['displayName'] as String?) ?? 'John Doe';
    final name = rawname; // Usar el nombre completo directo sin formatear
    final username = (_userDoc?['username'] as String?) ?? '@johndoe';
    final avatarUrl = (_userDoc?['avatarUrl'] as String?);
    final social = _userSocials.isNotEmpty
        ? _userSocials.map((e) => e['provider']!).toList()
        : ((_userDoc?['socialEcosystem'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const []);

    // Mostrar loading mientras carga
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // DEBUG: Verificar valores exactos antes de pasar a BackgroundImage
    final finalDisplayName = username.startsWith('@') ? username : '@$username';

    return Scaffold(
      body: BackgroundImage(
        avatarUrl: avatarUrl,
        name: name.isNotEmpty ? name : 'NOMBRE VACÍO',
        displayName: finalDisplayName,
        comunityCount: '1M',
        nameComunity: 'Community',
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
                onTap: () async {
                  final res = await context.push('/edit-profile');
                  if (res == 'updated') {
                    _loadUser();
                  }
                },
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
              links: _userSocials.isNotEmpty
                  ? _mapUserSocialDocsToLinks(_userSocials)
                  : _mapSocialToLinks(social, username),
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

  List<SocialLink> _mapSocialToLinks(List<String> platforms, String username) {
    final map = <SocialLink>[];
    final u = username.replaceFirst('@', '');
    for (final p in platforms) {
      switch (p.toLowerCase()) {
        case 'tiktok':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/TikTok.png',
              url: Uri.parse('https://www.tiktok.com/@$u'),
            ),
          );
          break;
        case 'instagram':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/Instagram.png',
              url: Uri.parse('https://www.instagram.com/$u'),
            ),
          );
          break;
        case 'x':
        case 'twitter':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/X.png',
              url: Uri.parse('https://x.com/$u'),
            ),
          );
          break;
        case 'pinterest':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/Pinterest.png',
              url: Uri.parse('https://www.pinterest.com/$u'),
            ),
          );
          break;
        case 'youtube':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/YouTube.png',
              url: Uri.parse('https://www.youtube.com/@$u'),
            ),
          );
          break;
        default:
          break;
      }
    }
    return map;
  }

  List<SocialLink> _mapUserSocialDocsToLinks(List<Map<String, String>> docs) {
    final map = <SocialLink>[];
    for (final m in docs) {
      final provider = (m['provider'] ?? '').toLowerCase();
      final url = m['url'] ?? '';
      String? asset;
      switch (provider) {
        case 'tiktok':
          asset = 'assets/icons/social_networks/TikTok.png';
          break;
        case 'instagram':
          asset = 'assets/icons/social_networks/Instagram.png';
          break;
        case 'x':
        case 'twitter':
          asset = 'assets/icons/social_networks/X.png';
          break;
        case 'pinterest':
          asset = 'assets/icons/social_networks/Pinterest.png';
          break;
        case 'youtube':
          asset = 'assets/icons/social_networks/YouTube.png';
          break;
        default:
          break;
      }
      if (asset != null && url.isNotEmpty) {
        map.add(SocialLink(asset: asset, url: Uri.parse(url)));
      }
    }
    return map;
  }
}
