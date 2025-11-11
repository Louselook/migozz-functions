import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileSearchScreen extends StatelessWidget {
  final UserDTO user;

  const ProfileSearchScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Reutilizamos la misma UI del profile normal
    return MobileProfileContent(
      user: user,
      tutorialKeys: TutorialKeys(), // o uno dummy si no se necesita
    );
  }
}
