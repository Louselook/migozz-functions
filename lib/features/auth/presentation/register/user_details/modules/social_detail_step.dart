import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import '../components/add_platform_bottom_sheet.dart';
import '../components/edit_platform_bottom_sheet.dart';
import '../components/platform_card.dart';

class SocialDetailScreen extends StatefulWidget {
  final String label;
  final String assetPath;

  const SocialDetailScreen({
    super.key,
    required this.label,
    required this.assetPath,
  });

  @override
  State<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends State<SocialDetailScreen> {
  List<Map<String, String>> addedPlatforms = [];

  void _showAddPlatformBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlatformBottomSheet(
        onPlatformAdded: (platformData) {
          setState(() {
            addedPlatforms.add(platformData);
          });
        },
      ),
    );
  }

  void _showEditPlatformBottomSheet(Map<String, String> platform, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPlatformBottomSheet(
        platform: platform,
        onPlatformUpdated: (updatedPlatform) {
          setState(() {
            addedPlatforms[index] = updatedPlatform;
          });
        },
        onPlatformDeleted: () {
          setState(() {
            addedPlatforms.removeAt(index);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.white),
        title: Text(
          "Your Social Ecosystem",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Add your platform",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),

            // Ícono grande
            SizedBox(height: 20),

            // Botón para agregar plataforma
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: _showAddPlatformBottomSheet,
                width: double.infinity,
                radius: 19,
                child: const Text(
                  "Add New Platform",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                gradient: AppColors.primaryGradient,
              ),
            ),

            const SizedBox(height: 20),

            // Lista de plataformas agregadas
            if (addedPlatforms.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Added Platforms:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        3, // 3 columnas para que se vean como cuadrados
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0, // Para que sean cuadrados perfectos
                  ),
                  itemCount: addedPlatforms.length,
                  itemBuilder: (context, index) {
                    final platform = addedPlatforms[index];
                    return PlatformCard(
                      platform: platform,
                      onTap: () =>
                          _showEditPlatformBottomSheet(platform, index),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
