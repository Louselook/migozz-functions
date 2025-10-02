import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
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
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> addedPlatforms = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Future<void> _fetchProfileAndPop() async {
    final cubit = context.read<RegisterCubit>();
    final usernameOrLink = _controller.text.trim();
    if (usernameOrLink.isEmpty) return;

    try {
      LoadingOverlay.show(context);
      await cubit.fetchSocialProfile(widget.label, usernameOrLink);

      final profile = cubit.state.userSocials?[widget.label];
      if (profile != null) {
        debugPrint(
          "✅ ${widget.label} profile data: "
          "username: ${profile.username}, "
          "fullName: ${profile.fullName}, "
          "url: ${profile.url}, "
          "followers: ${profile.followers}, "
          "followees: ${profile.followees}, "
          "totalPosts: ${profile.totalPosts}",
        );
      }

      if (!mounted) return;
      LoadingOverlay.hide(context);
      Navigator.of(context).pop();
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ${widget.label} profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.white),
        title: const Text(
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
            // TextField para añadir social
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Image.asset(widget.assetPath, width: 40, height: 40),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add ${widget.label.toUpperCase()}",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed:
                    _fetchProfileAndPop, // O puedes usar _showAddPlatformBottomSheet
                width: double.infinity,
                radius: 19,
                child: const Text(
                  "Continue / Add New Platform",
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
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
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
