import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserCard extends StatelessWidget {
  final UserDTO user;

  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl?.isNotEmpty == true;

    return GestureDetector(
      onTap: () {
        context.push('/profile-view', extra: user);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1️⃣ Fondo con gradiente (siempre presente)
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

            // 2️⃣ Imagen real SOLO si existe
            if (hasAvatar)
              CachedNetworkImage(
                imageUrl: user.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade900),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              ),

            // 3️⃣ Placeholder SOLO cuando NO hay avatar
            if (!hasAvatar) _buildPlaceholder(),

            // 4️⃣ Gradiente inferior con información del usuario
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.location.displayName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Usar el ancho menor para que sea cuadrado y centrado
          final size = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return SizedBox(
            width: size * 0.6, // 60% del espacio disponible
            height: size * 0.6,
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
