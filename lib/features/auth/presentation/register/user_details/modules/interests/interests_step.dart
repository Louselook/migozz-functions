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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  const PrimaryText(
                    'Choose Your Interests',
                    fontSize: 22,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  SecondaryText(
                    'Select what you\'re passionate about',
                    fontSize: 14,
                    color: Colors.grey,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final langCode = context.locale.languageCode;
                        final availableHeight = constraints.maxHeight;
                        final availableWidth = constraints.maxWidth;

                        final totalItems = allInterests.length;

                        // Base: item ~100px ancho, ~38px alto
                        const baseItemWidth = 100.0;
                        const baseItemHeight = 38.0;
                        const baseGap = 8.0;

                        // Items por fila según ancho
                        final itemsPerRow =
                            (availableWidth / (baseItemWidth + baseGap))
                                .floor()
                                .clamp(2, 5);
                        final totalRows = (totalItems / itemsPerRow).ceil();

                        // Altura total necesaria a escala 1.0
                        final neededHeight =
                            totalRows * (baseItemHeight + baseGap);

                        // Scale para que quepa todo - más agresivo
                        final scaleFactor = (availableHeight / neededHeight)
                            .clamp(0.5, 1.0);

                        final horizontalSpacing = 8.0 * scaleFactor;
                        final verticalSpacing = 8.0 * scaleFactor;

                        return Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.spaceEvenly,
                            spacing: horizontalSpacing,
                            runSpacing: verticalSpacing,
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
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.01,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                    ),
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
