import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/share_profile.dart';

class InfoUserProfile extends StatelessWidget {
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;

  const InfoUserProfile({
    super.key,
    required this.name,
    required this.displayName,
    required this.comunityCount,
    required this.nameComunity,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 05, sigmaY: 05),
        // filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(176, 0, 0, 0).withValues(alpha:0.05),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha:0.12)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha:0.35),
              ),
            ],
          ),
          alignment: Alignment.center, // centra el contenido vertical/horizontal
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 150),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Lógica para reproducir el audio
                    },
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 10), 
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ProfileQrScreen(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.share,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    comunityCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nameComunity,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
