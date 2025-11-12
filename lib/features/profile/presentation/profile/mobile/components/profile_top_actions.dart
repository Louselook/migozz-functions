import 'package:flutter/material.dart';

class ProfileTopActions extends StatelessWidget {
  final bool isOwnProfile;
  final VoidCallback onChatTap;
  final VoidCallback? onNotificationsTap;

  const ProfileTopActions({
    super.key,
    required this.isOwnProfile,
    required this.onChatTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      top: 45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onChatTap,
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            if (isOwnProfile) ...[
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onNotificationsTap ?? () {},
                child: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 33,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
