import 'package:flutter/material.dart';

class ProfileTopActions extends StatelessWidget {
  final bool isOwnProfile;
  final VoidCallback onChatTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onQrScanTap;
  final VoidCallback? onMenuTap;

  const ProfileTopActions({
    super.key,
    required this.isOwnProfile,
    required this.onChatTap,
    this.onNotificationsTap,
    this.onQrScanTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ BOTÓN IZQUIERDO (menú o regresar)
          !isOwnProfile? GestureDetector(
              onTap: onMenuTap,
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
                  size: 28,
                ),
              ),
            ):GestureDetector(
          onTap: onNotificationsTap ?? () {},
      child: const Icon(
        Icons.notifications_none_outlined,
        color: Colors.white,
        size: 28,
      ),
    ),

            // ✅ BOTONES DERECHOS (existentes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnProfile && onQrScanTap != null) ...[
                    GestureDetector(
                      onTap: onQrScanTap,
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],

                  if (isOwnProfile) ...[

                    GestureDetector(
                      onTap: onMenuTap ?? () {},
                      child: const Icon(
                  Icons.more_vert ,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
