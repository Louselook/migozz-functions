import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/v3/profile_page_v3.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

/// Pantalla para mostrar el perfil de un usuario buscado en la versión web
class ProfileSearchScreen extends StatelessWidget {
  final UserDTO user;

  const ProfileSearchScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Use V3 profile layout for the web profile search view
    return WebProfileContentV3(user: user, tutorialKeys: TutorialKeys());
  }
}
