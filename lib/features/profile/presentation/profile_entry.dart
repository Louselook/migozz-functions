// lib/features/profile/presentation/profile/profile_entry.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart'
    as mobile;
import 'package:migozz_app/features/profile/presentation/profile/shared/profile_wrapper.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_page.dart'
    as web;

/// Entry que decide si renderiza la UI web o mobile.
/// Ambos contenidos deben ser *presentational* y recibir los datos del usuario.
class ProfileEntry extends StatelessWidget {
  const ProfileEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileWrapper(
      builder: (context, authState) {
        // aquí authState.userProfile ya es seguro (no nulo)
        // pero por seguridad hacemos null-check
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

        // decide la UI
        if (PlatformUtils.isWeb) {
          // web_profile_content.dart debe exponer WebProfileContent({required user,...})
          return web.WebProfileContent(user: user);
        } else {
          // mobile/mobile_profile_content.dart debe exponer MobileProfileContent({required user,...})
          return mobile.MobileProfileContent(user: user);
        }
      },
    );
  }
}
