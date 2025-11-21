import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/profile_version_selector.dart';

/// Botón flotante para cambiar la versión del diseño de perfil
class ProfileVersionButton extends StatelessWidget {
  final int currentVersion;

  const ProfileVersionButton({super.key, required this.currentVersion});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                ProfileVersionSelector(currentVersion: currentVersion),
          );
        },
        backgroundColor: Colors.purple.withValues(alpha: 0.9),
        icon: const Icon(Icons.palette, color: Colors.white),
        label: Text(
          "profile.design.buttonText".tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
