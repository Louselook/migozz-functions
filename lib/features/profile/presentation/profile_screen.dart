// lib/features/profile/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/ai_assistant.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/presentation/profile_stats.dart';
import 'package:migozz_app/features/search/presentation/search_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // optional: when provided, show that user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  Map<String, dynamic>? _userDoc;
  List<Map<String, String>> _userSocials = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Obtiene las estadísticas sociales del usuario
  Future<List<SocialStats>> getUserSocialStats(String userId) async {
    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) return [];

    final fieldMapDoc = await db
        .collection('config')
        .doc('socialFieldMapping')
        .get();
    final fieldMap = fieldMapDoc.data() ?? {};

    final rawEco = userData['socialEcosystem'];
    if (rawEco == null) return [];

    final List<Map<String, dynamic>> ecosystem = [];

    if (rawEco is List) {
      for (final item in rawEco) {
        if (item is Map<String, dynamic>) ecosystem.add(item);
      }
    } else if (rawEco is Map) {
      for (final key in rawEco.keys) {
        final value = rawEco[key];
        if (value is Map<String, dynamic>) ecosystem.add(value);
      }
    }

    final List<SocialStats> statsList = [];
    for (final social in ecosystem) {
      final platformName = social.keys.first;
      final platformData = social[platformName];
      if (platformData is Map<String, dynamic>) {
        statsList.add(
          SocialStats.fromMap(platformName, platformData, fieldMap),
        );
      }
    }

    return statsList;
  }

  // Calcula el total de seguidores combinando todas las redes
  Future<int> getTotalFollowers(String userId) async {
    final stats = await getUserSocialStats(userId);

    // Debug opcional: muestra detalle por red
    for (final s in stats) {
      debugPrint('${s.name}: ${s.followers}');
    }

    final total = stats.fold<int>(0, (total, s) => total + s.followers);
    debugPrint('Total followers: $total');

    return total;
  }

  // Carga el documento del usuario actual
  Future<void> _loadUser() async {
    // If a userId was passed to the widget, show that profile; otherwise use current user
    final current = FirebaseAuth.instance.currentUser;
    final targetId = widget.userId ?? current?.uid;
    if (targetId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get();
      Map<String, dynamic>? data = doc.data();
      if (mounted) {
        setState(() {
          _userDoc = data;
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });

        final username = (data?['username'] as String?) ?? '';
        if (username.isNotEmpty) _loadUserSocials(username);
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Carga los documentos de redes sociales del usuario
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
    final bottomGradientHeight = size.height * 0.22;
    final bottomPaddingForCard = size.height * 0.25;
    final assistantSize = (size.width * 0.18).clamp(56.0, 88.0);

    final initialAssistantPosition = Offset(
      size.width - assistantSize - (size.width * 0.03),
      size.height - bottomPaddingForCard + (size.height * 0.03),
    );

    final initialSocialPosition = Offset(size.width - 65, size.height * 0.2);

    final rawname = (_userDoc?['displayName'] as String?) ?? 'Fullname';
    final name = formatDisplayName(rawname, format: FormatName.short);
    final username = (_userDoc?['username'] as String?) ?? '@username';
    final avatarUrl = (_userDoc?['avatarUrl'] as String?);
    final social = _userSocials.isNotEmpty
        ? _userSocials.map((e) => e['provider']!).toList()
        : ((_userDoc?['socialEcosystem'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const []);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final finalDisplayName = username.startsWith('@') ? username : '@$username';

    final current = FirebaseAuth.instance.currentUser;
    final targetId = widget.userId ?? current?.uid;

    return FutureBuilder<int>(
      future: targetId != null ? getTotalFollowers(targetId) : Future.value(0),
      builder: (context, snapshot) {
        final totalFollowers = snapshot.data ?? 0;

        return Scaffold(
          body: BackgroundImage(
            avatarUrl: avatarUrl,
            name: name.isNotEmpty ? name : 'NOMBRE VACÍO',
            displayName: finalDisplayName,
            comunityCount: totalFollowers
                .toString(), // total de followers combinados
            nameComunity: 'Community',
            child: Stack(
              children: [
                // Fondo degradado inferior
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

                // Botón de menú para busqueda de usuarios
                Positioned(
                  left: 20,
                  top: 70,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.search,
                      color: Color(0xAAFFFFFF),
                      size: 60,
                    ),
                  ),
                ),

                // Asistente IA flotante
                AIAssistant(
                  size: assistantSize,
                  initialPosition: initialAssistantPosition,
                  onTap: () => debugPrint('Asistente IA presionado'),
                ),

                // Panel lateral de redes sociales
                FutureBuilder<List<SocialStats>>(
                  future: targetId != null
                      ? getUserSocialStats(targetId)
                      : Future.value([]),
                  builder: (context, statsSnap) {
                    final stats = statsSnap.data ?? [];
                    final statsMap = {
                      for (final s in stats) s.name.toLowerCase(): s,
                    };
                    return DraggableSocialRail(
                      initialPosition: initialSocialPosition,
                      links: _userSocials.isNotEmpty
                          ? _mapUserSocialDocsToLinks(_userSocials, statsMap)
                          : _mapSocialToLinks(social, username, statsMap),
                      itemSize: 50,
                      iconSize: 45,
                    );
                  },
                ),

                // Navegación inferior
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GradientBottomNav(
                    currentIndex: _tab,
                    onItemSelected: (i) => setState(() => _tab = i),
                    onCenterTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mapea la lista de redes del ecosistema a objetos SocialLink
  List<SocialLink> _mapSocialToLinks(
    List<String> platforms,
    String username,
    Map<String, SocialStats>? statsMap,
  ) {
    final map = <SocialLink>[];
    final u = username.replaceFirst('@', '');
    for (final p in platforms) {
      final stat = statsMap?[p.toLowerCase()];
      switch (p.toLowerCase()) {
        case 'tiktok':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/TikTok.png',
              url: Uri.parse('https://www.tiktok.com/@$u'),
              followers: stat?.followers,
              shares: stat?.shares,
            ),
          );
          break;
        case 'instagram':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/Instagram.png',
              url: Uri.parse('https://www.instagram.com/$u'),
              followers: stat?.followers,
              shares: stat?.shares,
            ),
          );
          break;
        case 'x':
        case 'twitter':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/X.png',
              url: Uri.parse('https://x.com/$u'),
              followers: stat?.followers,
              shares: stat?.shares,
            ),
          );
          break;
        case 'pinterest':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/Pinterest.png',
              url: Uri.parse('https://www.pinterest.com/$u'),
              followers: stat?.followers,
              shares: stat?.shares,
            ),
          );
          break;
        case 'youtube':
          map.add(
            SocialLink(
              asset: 'assets/icons/social_networks/YouTube.png',
              url: Uri.parse('https://www.youtube.com/@$u'),
              followers: stat?.followers,
              shares: stat?.shares,
            ),
          );
          break;
        default:
          break;
      }
    }
    return map;
  }

  // Mapea los documentos de Firestore (userSocials) a objetos SocialLink
  List<SocialLink> _mapUserSocialDocsToLinks(
    List<Map<String, String>> docs,
    Map<String, SocialStats>? statsMap,
  ) {
    final map = <SocialLink>[];
    for (final m in docs) {
      final provider = (m['provider'] ?? '').toLowerCase();
      final url = m['url'] ?? '';
      String? asset;
      final stat = statsMap?[provider];
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
        map.add(
          SocialLink(
            asset: asset,
            url: Uri.parse(url),
            followers: stat?.followers,
            shares: stat?.shares,
          ),
        );
      }
    }
    return map;
  }
}
