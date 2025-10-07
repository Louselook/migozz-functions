import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileQrScreen extends StatelessWidget {
  const ProfileQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo con degradado (simplificado)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Contenido principal
          Column(
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
                    // QR Code
                    QrImageView(
                      data: "https://example.com/", // <-- Aca se enlaza el perfil por la URL
                      version: QrVersions.auto,
                      size: size.width * 0.5,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Taylor W",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "@taylorw",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Botón de compartir
              ElevatedButton.icon(
                onPressed: () {
                  // Logica para compartir
                },
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
                label: const Text("Share My Profile"),
              ),
            ],
          ),

          // Botón de cerrar
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
