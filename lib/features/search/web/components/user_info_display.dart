import 'package:flutter/material.dart';

/// Widget para mostrar información del usuario: displayName + username + badge verificado
class UserInfoDisplay extends StatelessWidget {
  final String displayName;
  final String username;
  final double displayNameFont;
  final double usernameFont;
  final double iconSize;
  final bool showVerifiedBadge;

  const UserInfoDisplay({
    super.key,
    required this.displayName,
    required this.username,
    required this.displayNameFont,
    required this.usernameFont,
    required this.iconSize,
    this.showVerifiedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: displayNameFont,
                    fontFamily: 'Roboto',
                  ),
                ),
                TextSpan(
                  text: ' @$username',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: usernameFont,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showVerifiedBadge) ...[
          const SizedBox(width: 4),
          Icon(Icons.verified, size: iconSize, color: const Color(0xFF1DA1F2)),
        ],
      ],
    );
  }
}
