import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Clase que maneja la presentación del tutorial del perfil principal
/// Implementa el flujo definido en Tutorial_Profile.md
class ProfileTutorialCoach {
  /// Muestra el tutorial completo del perfil
  /// 
  /// [context] - El BuildContext actual
  /// [keys] - Las keys de los elementos del tutorial
  /// [onFinish] - Callback cuando se completa el tutorial
  /// [onSkip] - Callback cuando se salta el tutorial
  static void showTutorial(
    BuildContext context,
    ProfileTutorialKeys keys, {
    VoidCallback? onFinish,
    VoidCallback? onSkip,
  }) {
    final targets = _buildTargets(context, keys);

    // Filtrar solo los targets que tienen context válido
    final validTargets = targets.where((t) {
      final key = t.keyTarget;
      if (key == null) return false;
      return key.currentContext != null;
    }).toList();

    if (validTargets.isEmpty) {
      debugPrint('⚠️ [ProfileTutorial] No hay targets válidos para mostrar');
      return;
    }

    debugPrint('🎓 [ProfileTutorial] Mostrando tutorial con ${validTargets.length} targets');

    TutorialCoachMark(
      targets: validTargets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      hideSkip: true,
      textSkip: 'tutorial.skip'.tr(),
      textStyleSkip: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 14,
        fontFamily: "inter",
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
      paddingFocus: 8,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 400),
      pulseAnimationDuration: const Duration(milliseconds: 750),
      pulseEnable: true,
      onFinish: () {
        debugPrint('🎉 [ProfileTutorial] Tutorial completado');
        onFinish?.call();
      },
      onSkip: () {
        debugPrint('⏭️ [ProfileTutorial] Tutorial saltado');
        onSkip?.call();
        return true;
      },
      onClickTarget: (target) {
        debugPrint('👆 [ProfileTutorial] Click en: ${target.identify}');
      },
    ).show(context: context);
  }

  /// Construye la lista de targets para el tutorial
  static List<TargetFocus> _buildTargets(
    BuildContext context,
    ProfileTutorialKeys keys,
  ) {
    return [
      // === Paso 1 - Home ===
      _buildTarget(
        identify: 'home_nav',
        key: keys.homeNavKey,
        title: 'tutorial.profile.home.title'.tr(),
        description: 'tutorial.profile.home.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
      ),

      // === Paso 1.1 - Search ===
      _buildTarget(
        identify: 'search_nav',
        key: keys.searchNavKey,
        title: 'tutorial.profile.search.title'.tr(),
        description: 'tutorial.profile.search.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
      ),

      // === Paso 1.2 - Messages (center) ===
      _buildTarget(
        identify: 'messages_nav',
        key: keys.messagesNavKey,
        title: 'tutorial.profile.messages.title'.tr(),
        description: 'tutorial.profile.messages.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
      ),

      // === Paso 1.3 - Stats ===
      _buildTarget(
        identify: 'stats_nav',
        key: keys.statsNavKey,
        title: 'tutorial.profile.stats.title'.tr(),
        description: 'tutorial.profile.stats.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
      ),

      // === Paso 1.4 - Settings ===
      _buildTarget(
        identify: 'settings_nav',
        key: keys.settingsNavKey,
        title: 'tutorial.profile.settings.title'.tr(),
        description: 'tutorial.profile.settings.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
        alignSkip: Alignment.topLeft,
      ),

      // === Paso 2 - Linked Networks ===
      _buildTarget(
        identify: 'linked_networks',
        key: keys.linkedNetworksKey,
        title: 'tutorial.profile.linkedNetworks.title'.tr(),
        description: 'tutorial.profile.linkedNetworks.description'.tr(),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.top,
        radius: 16,
      ),

      // === Paso 3 - Share QR ===
      _buildTarget(
        identify: 'share_qr',
        key: keys.shareQrKey,
        title: 'tutorial.profile.shareQr.title'.tr(),
        description: 'tutorial.profile.shareQr.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),

      // === Paso 4 - Community ===
      _buildTarget(
        identify: 'community',
        key: keys.communityKey,
        title: 'tutorial.profile.community.title'.tr(),
        description: 'tutorial.profile.community.description'.tr(),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
        radius: 12,
      ),

      // === Paso 5 - Messages Header ===
      _buildTarget(
        identify: 'messages_header',
        key: keys.messagesHeaderKey,
        title: 'tutorial.profile.messagesHeader.title'.tr(),
        description: 'tutorial.profile.messagesHeader.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),

      // === Paso 6 - Name Section ===
      _buildTarget(
        identify: 'name_section',
        key: keys.nameSectionKey,
        title: 'tutorial.profile.nameSection.title'.tr(),
        description: 'tutorial.profile.nameSection.description'.tr(),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
        radius: 16,
      ),

      // === Paso 7 - Notifications ===
      _buildTarget(
        identify: 'notifications',
        key: keys.notificationsKey,
        title: 'tutorial.profile.notifications.title'.tr(),
        description: 'tutorial.profile.notifications.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),

      // === Paso 8 - QR Scanner ===
      _buildTarget(
        identify: 'qr_scanner',
        key: keys.qrScannerKey,
        title: 'tutorial.profile.qrScanner.title'.tr(),
        description: 'tutorial.profile.qrScanner.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),

      // === Paso 9 - Edit Profile ===
      _buildTarget(
        identify: 'edit_profile',
        key: keys.editProfileKey,
        title: 'tutorial.profile.editProfile.title'.tr(),
        description: 'tutorial.profile.editProfile.description'.tr(),
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    ];
  }

  /// Construye un target individual con el estilo definido
  static TargetFocus _buildTarget({
    required String identify,
    required GlobalKey key,
    required String title,
    required String description,
    required ShapeLightFocus shape,
    required ContentAlign align,
    Alignment alignSkip = Alignment.topRight,
    double radius = 8,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      alignSkip: alignSkip,
      shape: shape,
      radius: radius,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: align,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          builder: (context, controller) {
            return _TutorialContent(
              title: title,
              description: description,
            );
          },
        ),
      ],
    );
  }
}

/// Widget para el contenido de cada paso del tutorial
class _TutorialContent extends StatelessWidget {
  final String title;
  final String description;

  const _TutorialContent({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          width: 2,
          color: Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con gradiente
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Descripción
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para la pantalla de bienvenida (Paso 0)
class TutorialWelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const TutorialWelcomeScreen({
    super.key,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Título con gradiente
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'tutorial.welcome.title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Descripción
              Text(
                'tutorial.welcome.description'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              // Botón de empezar
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStart,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Text(
                        'tutorial.welcome.start'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón de saltar
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'tutorial.welcome.skip'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
