import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

class UserCard extends StatelessWidget {
  final UserDTO user;

  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatarUrl?.isNotEmpty == true
        ? user.avatarUrl!
        : "https://i.imgur.com/BoN9kdC.png"; // sin foto es CJ

    return GestureDetector(
      onTap: () {
        context.push('/profile-view', extra: user);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(avatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.7),
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

            // para cuentas privadas, aun no existen tipos de cuentas
            // // Lock icon
            // Positioned(
            //   top: 8,
            //   right: 8,
            //   child: Icon(
            //     Icons.lock,
            //     color: Colors.white.withValues(alpha: 0.8),
            //     size: 22,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
