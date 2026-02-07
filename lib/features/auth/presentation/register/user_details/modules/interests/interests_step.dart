import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

/// Modelo para representar un interés del catálogo
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

  String getLocalizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? id;
  }
}

class InterestsStep extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;

  const InterestsStep({
    super.key,
    required this.controller,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  Set<String> selectedInterests = {};
  List<Interest> allInterests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
    _initializeSelectedInterests();
  }

  void _initializeSelectedInterests() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Map<String, List<String>> existingInterests = {};

      if (widget.mode == MoreUserDetailsMode.register) {
        final registerState = context.read<RegisterCubit>().state;
        existingInterests = registerState.interests ?? {};
      } else {
        final editState = context.read<EditCubit>().state;
        existingInterests = editState.interests ?? {};
      }

      setState(() {
        selectedInterests = existingInterests.values
            .expand((list) => list)
            .toSet();
      });
    });
  }

  Future<void> fetchCollection() async {
    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('interests_catalog_new')
          .get();

      final List<Interest> fetchedInterests = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['status'] != 'active') continue;

        Map<String, String> nameMap;
        if (data['name'] is Map) {
          nameMap = Map<String, String>.from(
            (data['name'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          );
        } else {
          nameMap = {
            'en': data['name']?.toString() ?? '',
            'es': data['name']?.toString() ?? '',
          };
        }

        fetchedInterests.add(
          Interest(
            id: doc.id,
            name: nameMap,
            emoji: data['emoji']?.toString() ?? '',
            order: data['order'] ?? 0,
            status: data['status'] ?? 'active',
          ),
        );
      }

      fetchedInterests.sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        allInterests = fetchedInterests;
        isLoading = false;
      });

      debugPrint('✅ Intereses cargados: ${allInterests.length}');
    } catch (e) {
      debugPrint('Error al traer datos: $e');
      setState(() => isLoading = false);
    }
  }

  void _updateCubit() {
    final selectedBySection = <String, List<String>>{
      'interests': selectedInterests.toList(),
    };

    if (widget.mode == MoreUserDetailsMode.register) {
      context.read<RegisterCubit>().setInterests(selectedBySection);
    } else {
      context.read<EditCubit>().updateInterests(selectedBySection);
    }
  }

  void _toggleInterest(String interestId) {
    setState(() {
      if (selectedInterests.contains(interestId)) {
        selectedInterests.remove(interestId);
      } else {
        selectedInterests.add(interestId);
      }
    });
    _updateCubit();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const PrimaryText('Choose Your Interests', fontSize: 22),
                  const SizedBox(height: 8),
                  SecondaryText(
                    'Select what you\'re passionate about',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final langCode = context.locale.languageCode;
                        final availableHeight = constraints.maxHeight;
                        final availableWidth = constraints.maxWidth;

                        // Calcular escala óptima según items y espacio disponible
                        final totalItems = allInterests.length;
                        const baseItemW = 120.0;
                        const baseRowH = 42.0;
                        const baseGap = 6.0;

                        double bestScale = 0.65;
                        for (int tryPerRow = 2; tryPerRow <= 5; tryPerRow++) {
                          final tryRows = (totalItems / tryPerRow).ceil();
                          final tryScale =
                              availableHeight / (tryRows * baseRowH);
                          final scaledStep = (baseItemW + baseGap) * tryScale;
                          final actualPerRow = (availableWidth / scaledStep)
                              .floor();
                          if (actualPerRow >= tryPerRow &&
                              tryScale > bestScale) {
                            bestScale = tryScale;
                          }
                        }
                        final scaleFactor = bestScale.clamp(0.65, 1.5);

                        final spacing = (6.0 * scaleFactor).clamp(4.0, 14.0);

                        return SizedBox(
                          width: availableWidth,
                          height: availableHeight,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.spaceEvenly,
                            spacing: spacing,
                            runSpacing: 0,
                            children: allInterests.map((interest) {
                              final isSelected = selectedInterests.contains(
                                interest.id,
                              );
                              return _interestChip(
                                name: interest.getLocalizedName(langCode),
                                emoji: interest.emoji,
                                selected: isSelected,
                                onTap: () => _toggleInterest(interest.id),
                                scaleFactor: scaleFactor,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Botón fijo abajo
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: _buildActionButton(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: () {
        _updateCubit();
        Navigator.of(context).pop('done');
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SecondaryText(
            widget.mode == MoreUserDetailsMode.register ? 'Continue' : 'Save',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _interestChip({
    required String name,
    String emoji = '',
    required bool selected,
    required VoidCallback onTap,
    double scaleFactor = 1.0,
  }) {
    final tileColor = Color.lerp(
      AppColors.greyBackground,
      AppColors.backgroundDark,
      0.6,
    )!;
    final borderRadius = BorderRadius.circular(20 * scaleFactor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: borderRadius,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * scaleFactor,
                vertical: 10 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: borderRadius,
              ),
              child: Text(
                emoji.isNotEmpty ? '$emoji$name' : name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15 * scaleFactor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20 * scaleFactor,
                  height: 20 * scaleFactor,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/icons/Migozz_Icon.png',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
