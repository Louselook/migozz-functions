import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/search/web/components/location_display.dart';
import 'package:migozz_app/features/search/web/components/user_avatar.dart';
import 'package:migozz_app/features/search/web/components/user_info_display.dart';

/// Card individual para mostrar un resultado de búsqueda de usuario
class SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final double scale;
  final VoidCallback? onTap;

  const SearchResultCard({
    super.key,
    required this.userData,
    required this.scale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = (24.0 * scale).clamp(20.0, 32.0);
    final containerPadding = (12.0 * scale).clamp(10.0, 16.0);
    final displayNameFont = (15.0 * scale).clamp(13.0, 18.0);
    final usernameFont = (13.0 * scale).clamp(11.0, 15.0);
    final iconSize = (16.0 * scale).clamp(14.0, 20.0);

    final avatar = userData['avatarUrl'] as String?;
    final displayName =
        _pickString(userData, [
          'displayName',
          'displayname',
          'display_name',
          'name',
          'fullName',
          'full_name',
        ]) ??
        _pickString(userData, ['userName', 'username']) ??
        'common.unknown'.tr();

    final username =
        _pickString(userData, ['userName', 'username', 'user', 'user_name']) ??
        '';

    final location = userData['location'] as Map<String, dynamic>?;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: containerPadding * 1.2,
          horizontal: containerPadding,
        ),
        decoration: BoxDecoration(
          color: const Color.fromARGB(20, 255, 255, 255),
          borderRadius: BorderRadius.circular(25),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Avatar
            UserAvatar(avatarUrl: avatar, radius: avatarRadius),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre de usuario + username + badge
                  UserInfoDisplay(
                    displayName: displayName,
                    username: username,
                    displayNameFont: displayNameFont,
                    usernameFont: usernameFont,
                    iconSize: iconSize,
                    showVerifiedBadge: userData['complete'] == true,
                  ),
                  // Ubicación
                  LocationDisplay(
                    city: location?['city'] as String?,
                    state: location?['state'] as String?,
                    country: location?['country'] as String?,
                    fontSize: usernameFont,
                    scale: scale,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper para leer distintos posibles nombres de campo
  String? _pickString(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
