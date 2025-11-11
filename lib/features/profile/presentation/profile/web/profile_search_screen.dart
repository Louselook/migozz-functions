import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_page.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

/// Pantalla para mostrar el perfil de un usuario buscado en la versión web
class ProfileSearchScreen extends StatelessWidget {
  final UserDTO user;

  const ProfileSearchScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Reutilizamos la misma UI del profile normal para web
    return WebProfileContent(
      user: user,
      tutorialKeys: TutorialKeys(), // o uno dummy si no se necesita
    );
  }
}
