import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/background_image.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/search/presentation/search_screen.dart';
import 'package:migozz_app/features/tutorial/profile_tutorial_helper.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final tutorialKeys = TutorialKeys();
  int _tab = 0;
  bool _hasNavigated = false;
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;
    final initialSocialPosition = Offset(size.width - 65, size.height * 0.2);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Detectar transición a perfil completo
        if (!authState.needsCompletion && !_tutorialShown) {
          _tutorialShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            debugPrint("🎓 Ejecutando tutorial de perfil...");
            await triggerProfileTutorial(context, tutorialKeys);
          });
        }

        // Usuario no autenticado
        if (!authState.isAuthenticated) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No hay usuario autenticado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Cargando perfil
        if (authState.isLoadingProfile) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // NAVEGACIÓN AUTOMÁTICA: Si necesita completar perfil, navegar a IA chat
        if (authState.needsCompletion && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint("🔀 [ProfileScreen] Navegando a completar perfil...");
            // context.go('/ia-chat', extra: authState.firebaseUser?.email ?? '');
            context.push('/complete-profile');
            // CompleteProfile
          });

          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Redirigiendo a completar perfil...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Si llegamos aquí, el perfil debe estar completo
        final user = authState.userProfile;
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Error: Perfil no encontrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Resetear flag de navegación cuando el perfil está completo
        _hasNavigated = false;

        // Preparar datos del perfil
        final rawName = user.displayName;
        final name = formatDisplayName(rawName, format: FormatName.short);
        final username = user.username.startsWith('@')
            ? user.username
            : '@${user.username}';
        final avatarUrl = user.avatarUrl;
        final voiceNoteUrl = user.voiceNoteUrl ?? '';
        final totalFollowers = _calculateTotalFollowers(user.socialEcosystem);
        final socialLinks = _buildSocialLinks(
          user.socialEcosystem,
          user.username,
        );

        return Scaffold(
          body: BackgroundImage(
            avatarUrl: avatarUrl,
            tutorialKeys: tutorialKeys,
            name: name.isNotEmpty ? name : 'NOMBRE VACÍO',
            displayName: username,
            comunityCount: totalFollowers.toString(),
            nameComunity: 'Community',
            voiceNoteUrl: voiceNoteUrl,
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

                // Botón de búsqueda
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
                    child: Container(
                      key: tutorialKeys.searchScreenKey,
                      child: const Icon(
                        Icons.search,
                        color: Color(0xAAFFFFFF),
                        size: 60,
                      ),
                    ),
                  ),
                ),

                // Panel lateral de redes sociales
                DraggableSocialRail(
                  initialPosition: initialSocialPosition,
                  links: socialLinks,
                  itemSize: 50,
                  iconSize: 45,
                ),

                // Navegación inferior
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GradientBottomNav(
                    currentIndex: _tab,
                    onItemSelected: (i) => setState(() => _tab = i),
                    onCenterTap: () async {
                      await context.read<AuthCubit>().logout();
                    },
                    onProfileUpdated: () {
                      context.read<AuthCubit>().refreshUserProfile();
                    },
                    tutorialKeys: tutorialKeys,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calcula el total de followers
  int _calculateTotalFollowers(List<Map<String, dynamic>>? socialEcosystem) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return 0;
    int total = 0;
    for (final social in socialEcosystem) {
      for (final platformData in social.values) {
        if (platformData is Map<String, dynamic>) {
          final followers = platformData['followers'];
          if (followers is int) {
            total += followers;
          } else if (followers is String) {
            total += int.tryParse(followers) ?? 0;
          }
        }
      }
    }
    return total;
  }

  /// Construye lista de SocialLink
  List<SocialLink> _buildSocialLinks(
    List<Map<String, dynamic>>? socialEcosystem,
    String username,
  ) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return [];
    final links = <SocialLink>[];
    final cleanUsername = username.replaceFirst('@', '');
    for (final social in socialEcosystem) {
      for (final entry in social.entries) {
        final platform = entry.key.toLowerCase();
        final data = entry.value;
        int? followers;
        int? shares;
        String? customUrl;
        if (data is Map<String, dynamic>) {
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();
        }
        final socialInfo = _getSocialInfo(platform, cleanUsername, customUrl);
        if (socialInfo != null) {
          links.add(
            SocialLink(
              asset: socialInfo['asset']!,
              url: Uri.parse(socialInfo['url']!),
              followers: followers,
              shares: shares,
            ),
          );
        }
      }
    }
    return links;
  }

  int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, String>? _getSocialInfo(
    String platform,
    String username,
    String? customUrl,
  ) {
    String? asset;
    String? url;
    switch (platform) {
      case 'tiktok':
        asset = 'assets/icons/social_networks/TikTok.png';
        url = customUrl ?? 'https://www.tiktok.com/@$username';
        break;
      case 'instagram':
        asset = 'assets/icons/social_networks/Instagram.png';
        url = customUrl ?? 'https://www.instagram.com/$username';
        break;
      case 'x':
      case 'twitter':
        asset = 'assets/icons/social_networks/X.png';
        url = customUrl ?? 'https://x.com/$username';
        break;
      case 'pinterest':
        asset = 'assets/icons/social_networks/Pinterest.png';
        url = customUrl ?? 'https://www.pinterest.com/$username';
        break;
      case 'youtube':
        asset = 'assets/icons/social_networks/YouTube.png';
        url = customUrl ?? 'https://www.youtube.com/@$username';
        break;
      default:
        return null;
    }
    return {'asset': asset, 'url': url};
  }
}
