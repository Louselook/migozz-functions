import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

/// Modelo de interés (igual que en interests_step.dart)
class Interest {
  final String id;
  final Map<String, String> name;
  final String emoji;
  final int order;
  final String status;

  Interest({
    required this.id,
    required this.name,
    required this.emoji,
    required this.order,
    required this.status,
  });

  String getLocalizedName(String languageCode) =>
      name[languageCode] ?? name['en'] ?? id;
}

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  Set<String> selectedInterests = {};
  List<Interest> allInterests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
  }

  Future<void> fetchCollection() async {
    try {
      setState(() => isLoading = true);

      // Cargar catálogo desde interests_catalog_new (igual que interests_step)
      final snapshot = await FirebaseFirestore.instance
          .collection('interests_catalog_new')
          .get();

      final List<Interest> fetchedInterests = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'active') continue;
        fetchedInterests.add(
          Interest(
            id: doc.id,
            name: data['name'] is Map
                ? Map<String, String>.from(data['name'])
                : {'en': data['name'], 'es': data['name']},
            emoji: data['emoji']?.toString() ?? '',
            order: data['order'] ?? 0,
            status: data['status'] ?? 'active',
          ),
        );
      }
      fetchedInterests.sort((a, b) => a.order.compareTo(b.order));

      // Obtener UID actual
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user logged in');
        setState(() {
          allInterests = fetchedInterests;
          isLoading = false;
        });
        return;
      }

      // Cargar intereses del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();
      final userInterests =
          userData?['interests'] as Map<String, dynamic>? ?? {};

      // Convertir el mapa a un set plano de IDs
      final selected = userInterests.values
          .expand((value) => List<String>.from(value))
          .toSet();

      setState(() {
        allInterests = fetchedInterests;
        selectedInterests = selected;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading interests: $e');
      setState(() => isLoading = false);
    }
  }

  // Helper para actualizar Firestore (llamado al guardar)
  Future<void> _saveInterests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('edit.validations.errorUserLogin'.tr())),
        );
      }
      return;
    }

    // Guardar como mapa con clave 'interests' igual que interests_step
    final res = {'interests': selectedInterests.toList()};

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'interests': res,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('edit.editInterest.saveInterest'.tr())),
        );
        Navigator.pop(context, "done");
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error saving interests: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('edit.editInterest.errorSave'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallDevice = screenHeight < 750;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "edit.editInterest.title".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    // Margen superior dinámico
                    SizedBox(height: isSmallDevice ? 10.h : 25.h),

                    PrimaryText(
                      'interestSelect.choose'.tr(),
                      fontSize: 22,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    SecondaryText(
                      'interestSelect.desc'.tr(),
                      fontSize: 14,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),

                    // ESPACIO FLEXIBLE CENTRAL
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              runAlignment: WrapAlignment.center,
                              spacing: 8.w,
                              runSpacing: 10.h,
                              children: allInterests.map((interest) {
                                return _interestChip(
                                  name: interest.getLocalizedName(
                                    context.locale.languageCode,
                                  ),
                                  emoji: interest.emoji,
                                  selected: selectedInterests.contains(
                                    interest.id,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedInterests.contains(interest.id)
                                          ? selectedInterests.remove(
                                              interest.id,
                                            )
                                          : selectedInterests.add(interest.id);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // BOTÓN SIEMPRE VISIBLE
                    Padding(
                      padding: EdgeInsets.only(bottom: 15.h, top: 10.h),
                      child: _buildActionButton(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _saveInterests,
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
          ),
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Center(
          child: Text(
            'buttons.save'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _interestChip({
    required String name,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji.isNotEmpty)
                Text(emoji, style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 4.w),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
