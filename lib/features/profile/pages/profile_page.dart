import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/service/profile_service.dart';
import 'package:migozz_app/features/social/service/social_service.dart';

class ProfileTestView extends StatefulWidget {
  const ProfileTestView({super.key});

  @override
  State<ProfileTestView> createState() => _ProfileTestViewState();
}

class _ProfileTestViewState extends State<ProfileTestView> {
  final profileService = ProfileService();
  final socialService = SocialService();
  final String uid = "testUser123"; // id quemado solo para pruebas

  String _log = "";

  void _appendLog(String msg) {
    setState(() {
      _log += "$msg\n";
    });
  }

  Future<void> _createUser() async {
    await profileService.createUserProfile(uid);
    _appendLog("✅ Usuario creado con ID: $uid");
  }

  Future<void> _getUser() async {
    final user = await profileService.getUserProfile(uid);
    _appendLog("📄 Perfil: $user");
  }

  Future<void> _addSocial() async {
    await socialService.addSocialLink(uid, "instagram_01", {
      'provider': 'instagram',
      'label': 'Instagram',
      'username': '@testuser',
      'url': 'https://instagram.com/testuser',
      'order': 1,
    });
    _appendLog("🔗 Instagram agregado");
  }

  Future<void> _getSocials() async {
    final socials = await socialService.getUserSocialLinks(uid);
    _appendLog("📱 Redes: $socials");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pruebas Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _createUser,
              child: const Text("Crear Usuario"),
            ),
            ElevatedButton(
              onPressed: _getUser,
              child: const Text("Ver Usuario"),
            ),
            ElevatedButton(
              onPressed: _addSocial,
              child: const Text("Agregar Social"),
            ),
            ElevatedButton(
              onPressed: _getSocials,
              child: const Text("Ver Redes"),
            ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(_log))),
          ],
        ),
      ),
    );
  }
}
