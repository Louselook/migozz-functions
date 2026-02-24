import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';

/// Clase que maneja la presentación del tutorial del perfil principal.
/// Diseño minimalista: sin overlay oscuro, solo un anillo gradiente
/// alrededor del icono objetivo + tooltip + botones Continuar / Saltar.
class ProfileTutorialCoach {
  /// Muestra el tutorial completo del perfil
  static void showTutorial(
    BuildContext context,
    ProfileTutorialKeys keys, {
    VoidCallback? onFinish,
    VoidCallback? onSkip,
  }) {
    final targets = _buildTargets(keys);

    // Filtrar solo los targets que tienen context válido
    final validTargets = targets
        .where((t) => t.key.currentContext != null)
        .toList();

    if (validTargets.isEmpty) {
      debugPrint('⚠️ [ProfileTutorial] No hay targets válidos para mostrar');
      return;
    }

    debugPrint(
      '🎓 [ProfileTutorial] Mostrando tutorial con ${validTargets.length} targets',
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => _MinimalTutorialOverlay(
          targets: validTargets,
          onFinish: onFinish,
          onSkip: onSkip,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Construye la lista de targets para el tutorial
  static List<_TutorialTarget> _buildTargets(ProfileTutorialKeys keys) {
    return [
      _TutorialTarget(
        identify: 'home_nav',
        key: keys.homeNavKey,
        title: 'tutorial.profile.home.title'.tr(),
        description: 'tutorial.profile.home.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'search_nav',
        key: keys.searchNavKey,
        title: 'tutorial.profile.search.title'.tr(),
        description: 'tutorial.profile.search.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'messages_nav',
        key: keys.messagesNavKey,
        title: 'tutorial.profile.messages.title'.tr(),
        description: 'tutorial.profile.messages.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'stats_nav',
        key: keys.statsNavKey,
        title: 'tutorial.profile.stats.title'.tr(),
        description: 'tutorial.profile.stats.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'settings_nav',
        key: keys.settingsNavKey,
        title: 'tutorial.profile.settings.title'.tr(),
        description: 'tutorial.profile.settings.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'linked_networks',
        key: keys.linkedNetworksKey,
        title: 'tutorial.profile.linkedNetworks.title'.tr(),
        description: 'tutorial.profile.linkedNetworks.description'.tr(),
        isRRect: true,
        horizontalInset: 40,
      ),
      _TutorialTarget(
        identify: 'share_qr',
        key: keys.shareQrKey,
        title: 'tutorial.profile.shareQr.title'.tr(),
        description: 'tutorial.profile.shareQr.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'community',
        key: keys.communityKey,
        title: 'tutorial.profile.community.title'.tr(),
        description: 'tutorial.profile.community.description'.tr(),
        isRRect: true,
      ),
      _TutorialTarget(
        identify: 'messages_header',
        key: keys.messagesHeaderKey,
        title: 'tutorial.profile.messagesHeader.title'.tr(),
        description: 'tutorial.profile.messagesHeader.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'name_section',
        key: keys.nameSectionKey,
        title: 'tutorial.profile.nameSection.title'.tr(),
        description: 'tutorial.profile.nameSection.description'.tr(),
        isRRect: true,
        horizontalInset: 60,
      ),
      _TutorialTarget(
        identify: 'notifications',
        key: keys.notificationsKey,
        title: 'tutorial.profile.notifications.title'.tr(),
        description: 'tutorial.profile.notifications.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'qr_scanner',
        key: keys.qrScannerKey,
        title: 'tutorial.profile.qrScanner.title'.tr(),
        description: 'tutorial.profile.qrScanner.description'.tr(),
      ),
      _TutorialTarget(
        identify: 'edit_profile',
        key: keys.editProfileKey,
        title: 'tutorial.profile.editProfile.title'.tr(),
        description: 'tutorial.profile.editProfile.description'.tr(),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de target
// ─────────────────────────────────────────────────────────────────────────────

class _TutorialTarget {
  final String identify;
  final GlobalKey key;
  final String title;
  final String description;
  final bool isRRect;
  final double horizontalInset;

  const _TutorialTarget({
    required this.identify,
    required this.key,
    required this.title,
    required this.description,
    this.isRRect = false,
    this.horizontalInset = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay minimalista (sin fondo oscuro)
// ─────────────────────────────────────────────────────────────────────────────

class _MinimalTutorialOverlay extends StatefulWidget {
  final List<_TutorialTarget> targets;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;

  const _MinimalTutorialOverlay({
    required this.targets,
    this.onFinish,
    this.onSkip,
  });

  @override
  State<_MinimalTutorialOverlay> createState() =>
      _MinimalTutorialOverlayState();
}

class _MinimalTutorialOverlayState extends State<_MinimalTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.targets.length - 1) {
      _animController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentIndex++);
        _animController.forward();
      });
    } else {
      _finish();
    }
  }

  void _skip() {
    debugPrint('⏭️ [ProfileTutorial] Tutorial saltado');
    widget.onSkip?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _finish() {
    debugPrint('🎉 [ProfileTutorial] Tutorial completado');
    widget.onFinish?.call();
    if (mounted) Navigator.of(context).pop();
  }

  /// Obtiene la posición y tamaño del widget target actual.
  Rect? _getTargetRect() {
    final target = widget.targets[_currentIndex];
    final renderBox =
        target.key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.targets[_currentIndex];
    final targetRect = _getTargetRect();
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Toca cualquier lugar para avanzar al siguiente paso
            Positioned.fill(
              child: GestureDetector(
                onTap: _next,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

            // Anillo gradiente alrededor del target
            if (targetRect != null)
              _GradientRing(
                targetRect: targetRect,
                isRRect: target.isRRect,
                horizontalInset: target.horizontalInset,
              ),

            // Tooltip con título y descripción
            if (targetRect != null)
              _TutorialTooltip(
                targetRect: targetRect,
                title: target.title,
                description: target.description,
                screenSize: screenSize,
              ),

            // Skip + indicador de progreso (arriba, centrado)
            Positioned(
              top: topPadding + 8,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Saltar
                  GestureDetector(
                    onTap: _skip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'tutorial.skipTutorial'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'inter',
                          color: Colors.white.withValues(alpha: 0.7),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Indicador de progreso (dots)
                  _StepIndicator(
                    current: _currentIndex,
                    total: widget.targets.length,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anillo gradiente alrededor del target
// ─────────────────────────────────────────────────────────────────────────────

class _GradientRing extends StatefulWidget {
  final Rect targetRect;
  final bool isRRect;
  final double horizontalInset;

  const _GradientRing({
    required this.targetRect,
    this.isRRect = false,
    this.horizontalInset = 0,
  });

  @override
  State<_GradientRing> createState() => _GradientRingState();
}

class _GradientRingState extends State<_GradientRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 6;
    const double strokeWidth = 2.5;

    final rect = widget.targetRect;
    final isCircle = !widget.isRRect;
    final diameter = isCircle
        ? math.max(rect.width, rect.height) + padding * 2
        : 0.0;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final opacity = _pulseAnim.value;
        if (isCircle) {
          final centerX = rect.center.dx;
          final centerY = rect.center.dy;
          return Positioned(
            left: centerX - diameter / 2 - strokeWidth,
            top: centerY - diameter / 2 - strokeWidth,
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: Size(
                  diameter + strokeWidth * 2,
                  diameter + strokeWidth * 2,
                ),
                painter: _GradientCirclePainter(
                  gradient: AppColors.primaryGradient,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          );
        } else {
          // RRect
          final inset = widget.horizontalInset;
          return Positioned(
            left: rect.left - padding - strokeWidth + inset,
            top: rect.top - padding - strokeWidth,
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: Size(
                  rect.width + (padding + strokeWidth) * 2 - inset * 2,
                  rect.height + (padding + strokeWidth) * 2,
                ),
                painter: _GradientRRectPainter(
                  gradient: AppColors.primaryGradient,
                  strokeWidth: strokeWidth,
                  borderRadius: 16,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters para el contorno gradiente
// ─────────────────────────────────────────────────────────────────────────────

class _GradientCirclePainter extends CustomPainter {
  final LinearGradient gradient;
  final double strokeWidth;

  _GradientCirclePainter({required this.gradient, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientCirclePainter oldDelegate) => false;
}

class _GradientRRectPainter extends CustomPainter {
  final LinearGradient gradient;
  final double strokeWidth;
  final double borderRadius;

  _GradientRRectPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientRRectPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tooltip flotante
// ─────────────────────────────────────────────────────────────────────────────

class _TutorialTooltip extends StatelessWidget {
  final Rect targetRect;
  final String title;
  final String description;
  final Size screenSize;

  const _TutorialTooltip({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar arriba o abajo según la posición del target
    final showAbove = targetRect.center.dy > screenSize.height * 0.5;

    const double tooltipMargin = 12;
    const double horizontalPadding = 24;
    const double maxWidth = 300;

    // Centrar horizontalmente respecto al target
    double left = targetRect.center.dx - maxWidth / 2;
    if (left < horizontalPadding) left = horizontalPadding;
    if (left + maxWidth > screenSize.width - horizontalPadding) {
      left = screenSize.width - horizontalPadding - maxWidth;
    }

    final double top;
    if (showAbove) {
      top = targetRect.top - tooltipMargin - 100;
    } else {
      top = targetRect.bottom + tooltipMargin;
    }

    return Positioned(
      left: left,
      top: top.clamp(8.0, screenSize.height - 180),
      child: SizedBox(
        width: maxWidth,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicador de progreso (dots)
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

/// Widget para la pantalla de bienvenida (Paso 0) – modal centrado
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
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con gradiente
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'tutorial.welcome.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Descripción
            Text(
              'tutorial.welcome.description'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 28),
            // Botón de empezar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStart,
                    borderRadius: BorderRadius.circular(25),
                    child: Center(
                      child: Text(
                        'tutorial.welcome.start'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón de saltar
            TextButton(
              onPressed: onSkip,
              child: Text(
                'tutorial.welcome.skip'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
