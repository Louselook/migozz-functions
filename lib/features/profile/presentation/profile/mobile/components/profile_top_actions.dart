import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/profile/components/follow_button.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';

class ProfileTopActions extends StatefulWidget {
  final bool isOwnProfile;
  final VoidCallback onChatTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onQrScanTap;
  final VoidCallback? onMenuTap;
  final int profilePercentage;
  final String? targetUserId;
  final String? currentUserId;
  final ProfileTutorialKeys? profileTutorialKeys;
  final bool isAuthenticated;

  const ProfileTopActions({
    super.key,
    required this.isOwnProfile,
    required this.onChatTap,
    this.onNotificationsTap,
    this.onQrScanTap,
    this.onMenuTap,
    this.profilePercentage = 100,
    this.targetUserId,
    this.currentUserId,
    this.profileTutorialKeys,
    this.isAuthenticated = true,
  });

  @override
  State<ProfileTopActions> createState() => _ProfileTopActionsState();
}

class _ProfileTopActionsState extends State<ProfileTopActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _pulseCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 666),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount++;
        if (_pulseCount < 4 &&
            widget.profilePercentage < 80 &&
            widget.isOwnProfile) {
          _pulseController.forward();
        }
      }
    });

    // Start pulse animation if profile is incomplete
    if (widget.profilePercentage < 80 && widget.isOwnProfile) {
      _pulseController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldPulse = widget.profilePercentage < 80 && widget.isOwnProfile;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ BOTÓN IZQUIERDO (menú o regresar)
            !widget.isOwnProfile
                ? GestureDetector(
                    onTap: widget.onMenuTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFFFFFFF),
                        size: 32,
                      ),
                    ),
                  )
                : GestureDetector(
                    key: widget.profileTutorialKeys?.notificationsKey,
                    onTap: widget.onNotificationsTap ?? () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

            // ✅ BOTONES DERECHOS (existentes)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de Follow para perfiles de otros usuarios (autenticado)
                if (!widget.isOwnProfile &&
                    widget.isAuthenticated &&
                    widget.targetUserId != null &&
                    widget.currentUserId != null) ...[
                  FollowButton(
                    targetUserId: widget.targetUserId!,
                    currentUserId: widget.currentUserId!,
                    compact: true,
                  ),
                ],
                // Botón de Follow para no autenticados — abre login prompt
                if (!widget.isOwnProfile && !widget.isAuthenticated) ...[
                  GestureDetector(
                    onTap: () => _showLoginPrompt(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0050), Color(0xFFFF6B9D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                // Solo mostrar el contenedor de acciones si es perfil propio
                if (widget.isOwnProfile) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onQrScanTap != null) ...[
                          GestureDetector(
                            key: widget.profileTutorialKeys?.qrScannerKey,
                            onTap: widget.onQrScanTap,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
                          key: widget.profileTutorialKeys?.editProfileKey,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onMenuTap?.call();
                          },
                          child: ScaleTransition(
                            scale: shouldPulse
                                ? _pulseAnimation
                                : const AlwaysStoppedAnimation(1.0),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => AppColors
                                    .primaryGradient
                                    .createShader(bounds),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Join Migozz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Log in or sign up to follow, chat and send gifts.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.go('/register');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0050),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
