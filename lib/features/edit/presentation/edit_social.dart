import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';
import 'package:migozz_app/features/edit/presentation/social_detail_edit.dart';

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

class EditSocialScreen extends StatefulWidget {
  const EditSocialScreen({super.key});

  @override
  State<EditSocialScreen> createState() => _EditSocialScreenState();
}

class _EditSocialScreenState extends State<EditSocialScreen> {
  bool isLoading = true;
  Set<String> selectedSocials = {};
  late Map<String, String> iconByLabel;

  final List<String> socials = [
    "Tiktok",
    "Instagram",
    "Facebook",
    "Youtube",
    "Telegram",
    "Whatsapp",
    "Pinterest",
    "Spotify",
    "X",
    "LinkedIn",
    "Paypal",
    "Xbox",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    iconByLabel = {
      "Tiktok": "assets/icons/social_networks/TikTok.png",
      "Instagram": "assets/icons/social_networks/Instagram.png",
      "Facebook": "assets/icons/social_networks/Facebook.png",
      "Youtube": "assets/icons/social_networks/Youtube.png",
      "Telegram": "assets/icons/social_networks/Telegram.png",
      "Whatsapp": "assets/icons/social_networks/WhatsApp.png",
      "Pinterest": "assets/icons/social_networks/Pinterest.png",
      "Spotify": "assets/icons/social_networks/Spotify.png",
      "X": "assets/icons/social_networks/X.png",
      "LinkedIn": "assets/icons/social_networks/LinkedIn.png",
      "Paypal": "assets/icons/social_networks/Paypal.svg",
      "Xbox": "assets/icons/social_networks/Xbox.svg",
      "Other": "assets/icons/social_networks/Other.png",
    };

    fetchSocials();
  }

  Future<void> fetchSocials() async {
    try {
      setState(() => isLoading = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint("❌ No user logged in");
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          selectedSocials = {};
          isLoading = false;
        });
        return;
      }

      Set<String> socialsFound = {};

      // 1. Leer 'socials' clásico
      if (data['socials'] != null) {
        final socialsData = Map<String, dynamic>.from(data['socials']);
        socialsFound.addAll(
          socialsData.keys.map((k) => k.toString().toLowerCase()).toSet(),
        );
      }

      // 2. Leer 'socialEcosystem' nuevo
      if (data['socialEcosystem'] != null &&
          data['socialEcosystem'] is List &&
          data['socialEcosystem'].isNotEmpty) {

        for (final item in data['socialEcosystem']) {
          final map = Map<String, dynamic>.from(item);
          for (final key in map.keys) {
            socialsFound.add(key.toString().toLowerCase());
          }
        }
      }

      setState(() {
        selectedSocials = socialsFound;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("🔥 Error fetching socials: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = context.scaleFactor;

    final horizontalPadding = ResponsiveUtils.scaleValue(
      20.0,
      scaleFactor,
      minValue: 16.0,
      maxValue: 28.0,
    );
    final topSpacing = ResponsiveUtils.scaleValue(
      16.0,
      scaleFactor,
      minValue: 12.0,
      maxValue: 24.0,
    );

    const crossAxisCount = 3;
    const crossAxisSpacing = 16.0;
    const mainAxisSpacing = 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Edit Socials",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: topSpacing),
                  const SecondaryText("Add your platforms"),
                  SizedBox(height: topSpacing),

                  // Grid con íconos
                  Expanded(
                    child: GridView.builder(
                      itemCount: socials.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: mainAxisSpacing,
                        crossAxisSpacing: crossAxisSpacing,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final label = socials[index];
                        final assetPath = iconByLabel[label] ?? "";
                        final selected = selectedSocials.contains(label.toLowerCase());

                        return SocialIconCard(
                          label: label,
                          assetPath: assetPath,
                          isSelected: selected,
                          onTap: () async {
                            setState(() {
                              final lower = label.toLowerCase();
                              if (selectedSocials.contains(lower)) {
                                selectedSocials.remove(lower);
                              } else {
                                selectedSocials.add(lower);
                              }
                            });
                            if (label == "Other" && !selected) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SocialDetailScreen(
                                    label: label,
                                    assetPath: assetPath,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // Botón Save
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C3B), Color(0xFF9D1FFF)],
                      ),
                    ),
                    child: TextButton(
                      onPressed: saveSocials,
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> saveSocials() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await userRef.get();
      final data = snapshot.data();

      // Estado anterior
      final oldEcosystem = data?['socialEcosystem'] ?? [];
      final oldSocials = <String>{};
      for (final item in oldEcosystem) {
        final map = Map<String, dynamic>.from(item);
        for (final key in map.keys) {
          oldSocials.add(key.toLowerCase());
        }
      }

      // Diferencia para detectar eliminaciones
      final removedSocials = oldSocials.difference(selectedSocials);

      // Confirmación si se quitaron redes
      if (removedSocials.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              "Disconnect socials",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Are you sure you want to disconnect ${removedSocials.join(', ')} from your ecosystem?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("OK", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );

        if (confirmed != true) return; // No continuar si canceló
      }

      // Crear el nuevo socialEcosystem con formato original
      final updatedEcosystem = [
        for (final social in selectedSocials)
          {social.toLowerCase(): {"active": true}}
      ];

      // Si se eliminaron redes, limpiar el array anterior
      List<Map<String, Map<String, dynamic>>> finalEcosystem = List.from(updatedEcosystem);

      if (removedSocials.isNotEmpty) {
        // filtramos cualquier posible resto
        finalEcosystem = updatedEcosystem
            .where((item) {
              final key = item.keys.first.toLowerCase();
              return !removedSocials.contains(key);
            })
            .toList();
      }

      // Guardar el resultado final con formato correcto
      await userRef.update({'socialEcosystem': finalEcosystem});

      // Actualizar cubit/local state
      final cubit = context.read<RegisterCubit>();
      cubit.setSocialEcosystem(finalEcosystem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Socials updated successfully!')),
        );
        Navigator.pop(context, "done");
      }
    } on FirebaseException catch (e) {
      debugPrint("Error saving socials: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving socials')),
      );
    }
  }
}
