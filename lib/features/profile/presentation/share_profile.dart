import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla que muestra un QR y permite compartir el enlace del perfil
/// de un usuario. Si no se pasa [userId], se usa el usuario logueado.
class ProfileQrScreen extends StatefulWidget {
  final String?
  userId; // Usuario objetivo (otro perfil). Si es null => current user
  final String?
  overrideUsername; // Permite pasar username directo y evitar fetch
  final String?
  overrideDisplayName; // Permite pasar displayName directo y evitar fetch

  const ProfileQrScreen({
    super.key,
    this.userId,
    this.overrideUsername,
    this.overrideDisplayName,
  });

  @override
  State<ProfileQrScreen> createState() => _ProfileQrScreenState();
}

class _ProfileQrScreenState extends State<ProfileQrScreen> {
  late Future<_ProfileData> _futureProfile;

  static const String _baseProfileUrl =
      'https://migozz.app/u'; // Cambia a tu dominio real

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    // Si ya vienen los datos, retornarlos sin ir a Firestore
    if (widget.overrideUsername != null && widget.overrideDisplayName != null) {
      final link = _buildUrl(widget.overrideUsername!);
      return _ProfileData(
        username: widget.overrideUsername!,
        displayName: widget.overrideDisplayName!,
        link: link,
      );
    }

    final current = FirebaseAuth.instance.currentUser;
    final targetId = widget.userId ?? current?.uid;
    if (targetId == null) {
      return _ProfileData(
        username: 'unknown',
        displayName: 'Unknown',
        link: _buildUrl('unknown'),
      );
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get();
      final data = doc.data() ?? {};
      final usernameRaw = (data['username'] as String?) ?? 'user';
      final username = usernameRaw.replaceFirst('@', '');
      final displayName = (data['displayName'] as String?) ?? username;
      final link = _buildUrl(username);
      return _ProfileData(
        username: username,
        displayName: displayName,
        link: link,
      );
    } catch (e) {
      debugPrint('Error cargando perfil para QR: $e');
      return _ProfileData(
        username: 'error',
        displayName: 'Error',
        link: _buildUrl('error'),
      );
    }
  }

  String _buildUrl(String username) =>
      '$_baseProfileUrl/${username.toLowerCase()}';

  void _shareProfile(_ProfileData data) {
    Share.share(
      'Mira el perfil de ${data.displayName} en Migozz: ${data.link}',
      subject: 'Perfil de ${data.displayName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          FutureBuilder<_ProfileData>(
            future: _futureProfile,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (!snap.hasData) {
                return const Text(
                  'No data',
                  style: TextStyle(color: Colors.white),
                );
              }
              final data = snap.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: size.width * 0.7,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: data.link,
                          version: QrVersions.auto,
                          size: size.width * 0.5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${data.username}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => _shareProfile(data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Profile'),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  final String username;
  final String displayName;
  final String link;
  _ProfileData({
    required this.username,
    required this.displayName,
    required this.link,
  });
}
