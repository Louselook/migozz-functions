import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

/// Card individual para mostrar un usuario real en el grid de búsqueda
class SuggestionCard extends StatelessWidget {
  final UserDTO user;

  const SuggestionCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl?.isNotEmpty == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (user.username.isNotEmpty) {
              context.go('/u/${user.username}');
            } else {
              context.push('/profile-view', extra: user);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fondo con gradiente (siempre presente)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.5),
                      Colors.black,
                    ],
                  ),
                ),
              ),

              // 2. Avatar real si existe
              if (hasAvatar)
                CachedNetworkImage(
                  imageUrl: user.avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade900),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                ),

              // 3. Placeholder cuando no hay avatar
              if (!hasAvatar) _buildPlaceholder(),

              // 4. Gradiente inferior con info del usuario
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.location.displayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: SvgPicture.asset(
              AssetsConstants.placeholderIcon,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
          );
        },
      ),
    );
  }
}
