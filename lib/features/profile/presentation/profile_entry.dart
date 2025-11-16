// lib/features/profile/presentation/profile/profile_entry.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart'
    as mobile_v1;
import 'package:migozz_app/features/profile/presentation/profile/mobile/v2/profile_screen_v2.dart'
    as mobile_v2;
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/profile_screen_v3.dart'
    as mobile_v3;
import 'package:migozz_app/features/profile/presentation/profile/shared/profile_wrapper.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_page.dart'
    as web_v1;
import 'package:migozz_app/features/profile/presentation/profile/web/v2/profile_page_v2.dart'
    as web_v2;
import 'package:migozz_app/features/profile/presentation/profile/web/v3/profile_page_v3.dart'
    as web_v3;

/// Entry que decide si renderiza la UI web o mobile y qué versión según preferencia del usuario.
/// Ambos contenidos deben ser *presentational* y recibir los datos del usuario.
class ProfileEntry extends StatelessWidget {
  const ProfileEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileWrapper(
      builder: (context, authState, tutorialKeys) {
        final user = authState.userProfile;
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No hay usuario',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Leer la versión de perfil preferida del usuario (1, 2 o 3)
        final profileVersion = user.profileVersion;

        // decide la UI según plataforma y versión
        if (PlatformUtils.isWeb) {
          switch (profileVersion) {
            case 2:
              return web_v2.WebProfileContentV2(
                user: user,
                tutorialKeys: tutorialKeys,
              );
            case 3:
              return web_v3.WebProfileContentV3(
                user: user,
                tutorialKeys: tutorialKeys,
              );
            default:
              return web_v1.WebProfileContent(
                user: user,
                tutorialKeys: tutorialKeys,
              );
          }
        } else {
          switch (profileVersion) {
            case 2:
              return mobile_v2.MobileProfileContentV2(
                user: user,
                tutorialKeys: tutorialKeys,
              );
            case 3:
              return mobile_v3.MobileProfileContentV3(
                user: user,
                tutorialKeys: tutorialKeys,
              );
            default:
              return mobile_v1.MobileProfileContent(
                user: user,
                tutorialKeys: tutorialKeys,
              );
          }
        }
      },
    );
  }
}
