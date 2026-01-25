import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/follow_button.dart';

class ProfileTopActions extends StatefulWidget {
  final bool isOwnProfile;
  final VoidCallback onChatTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onQrScanTap;
  final VoidCallback? onMenuTap;
  final int profilePercentage;
  final String? targetUserId;
  final String? currentUserId;

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
      duration: const Duration(milliseconds: 600),
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
        if (_pulseCount < 3 &&
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
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      child: Icon(
                        Icons.arrow_back,
                        color: const Color(0xFFFFFFFF),
                        size: 32,
                      ),
                    ),
                  )
                : GestureDetector(
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
                // Botón de Follow para perfiles de otros usuarios
                if (!widget.isOwnProfile &&
                    widget.targetUserId != null &&
                    widget.currentUserId != null) ...[
                  FollowButton(
                    targetUserId: widget.targetUserId!,
                    currentUserId: widget.currentUserId!,
                    compact: true,
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
                          onTap: widget.onMenuTap ?? () {},
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
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 20,
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
}
