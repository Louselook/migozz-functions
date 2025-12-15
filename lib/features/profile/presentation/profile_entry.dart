// lib/features/profile/presentation/profile/profile_entry.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart'
    as mobile_v1;
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart'
    as mobile_v3;

import 'package:migozz_app/features/profile/presentation/profile/shared/profile_wrapper.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_page.dart'
    as web_v1;
import 'package:migozz_app/features/profile/presentation/profile/web/v2/profile_page_v2.dart'
    as web_v2;
import 'package:migozz_app/features/profile/presentation/profile/web/v3/profile_page_v3.dart'
    as web_v3;
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileEntry extends StatelessWidget {
  final TutorialKeys tutorialKeys; // ← Recibir como parámetro requerido

  const ProfileEntry({
    super.key,
    required this.tutorialKeys, // ← Hacerlo requerido
  });

  @override
  Widget build(BuildContext context) {
    return ProfileWrapper(
      tutorialKeys: tutorialKeys, // ← Pasar al wrapper
      builder: (context, authState, receivedKeys) {
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

        final profileVersion = 3;

        if (PlatformUtils.isWeb) {
          switch (profileVersion) {
            case 2:
              return web_v2.WebProfileContentV2(
                user: user,
                tutorialKeys: receivedKeys, // ← Usar las keys recibidas
              );
            case 3:
              return web_v3.WebProfileContentV3(
                user: user,
                tutorialKeys: receivedKeys,
              );
            default:
              return web_v1.WebProfileContent(
                user: user,
                tutorialKeys: receivedKeys,
              );
          }
        } else {
          switch (profileVersion) {
            case 3:
              return mobile_v3.ProfileScreem(
                user: user,
                tutorialKeys: receivedKeys,
              );
            default:
              return mobile_v1.ProfileScreem(
                user: user,
                tutorialKeys: receivedKeys,
              );
          }
        }
      },
    );
  }
}
