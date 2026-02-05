import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

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
  List<String> allInterests = [];
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

      CollectionReference collection = FirebaseFirestore.instance.collection(
        'interests_catalog',
      );
      QuerySnapshot snapshot = await collection.get();

      List<String> fetchedInterests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data.forEach((categoryTitle, categoryOptions) {
          if (categoryOptions is List) {
            for (var option in categoryOptions) {
              fetchedInterests.add(option.toString());
            }
          }
        });
      }

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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const PrimaryText('Choose Your Interests'),
                        const SizedBox(height: 8),
                        SecondaryText(
                          'Select what you\'re passionate about',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        // Wrap fluido - se organizan dinámicamente
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 10,
                          children: allInterests.map((interest) {
                            final isSelected = selectedInterests.contains(
                              interest,
                            );
                            return _interestChip(
                              name: interest,
                              selected: isSelected,
                              onTap: () => _toggleInterest(interest),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Botón fijo abajo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _buildActionButton(),
                ),
              ],
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
    required bool selected,
    required VoidCallback onTap,
  }) {
    final tileColor = Color.lerp(
      AppColors.greyBackground,
      AppColors.backgroundDark,
      0.6,
    )!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
