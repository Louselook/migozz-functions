import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/interest_section_model.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';

// Cambia, va para chat
class InterestsStep extends StatefulWidget {
  final PageController controller;
  const InterestsStep({super.key, required this.controller});

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  Set<String> selectedInterests = {};
  List<InterestSectionModel> dynamicSections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Cargar datos de Firebase al inicializar la vista
    fetchCollection();
  }

  Future<void> fetchCollection() async {
    try {
      setState(() {
        isLoading = true;
      });

      CollectionReference collection = FirebaseFirestore.instance.collection(
        'interests_catalog',
      );
      QuerySnapshot snapshot = await collection.get();

      List<InterestSectionModel> fetchedSections = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Cada campo es una lista de strings (opciones de esa categoría)
        data.forEach((categoryTitle, categoryOptions) {
          if (categoryOptions is List) {
            fetchedSections.add(
              InterestSectionModel(
                title: categoryTitle,
                options: List<String>.from(categoryOptions),
                expanded: false,
              ),
            );
          }
        });
      }

      setState(() {
        dynamicSections = fetchedSections;
        isLoading = false;
      });

      debugPrint(
        '✅ Secciones cargadas desde Firebase: ${dynamicSections.length}',
      );
    } catch (e) {
      debugPrint('Error al traer datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateCubit() {
    final cubit = context.read<RegisterCubit>();

    // Agrupar intereses por sección (usando datos dinámicos de Firebase)
    final Map<String, List<String>> interestsBySection = {};
    for (var section in dynamicSections) {
      final selectedInSection = section.options
          .where((opt) => selectedInterests.contains(opt))
          .toList();
      if (selectedInSection.isNotEmpty) {
        interestsBySection[section.title] = selectedInSection;
      }
    }

    // Guardar en el cubit
    cubit.setInterests(interestsBySection);

    // debugPrint("✅ Intereses guardados: ${cubit.state.interests}");

    // Solo llamas al método final de registro
    cubit.completeRegistration();
  }

  /// --- Nueva lógica tipo acordeón ---
  void _toggleSection(int tappedIndex) {
    setState(() {
      for (int i = 0; i < dynamicSections.length; i++) {
        if (i == tappedIndex) {
          dynamicSections[i].expanded = !dynamicSections[i].expanded;
        } else {
          dynamicSections[i].expanded = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText('Choose Your Interest'),
            const SizedBox(height: 20),

            // secciones
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dynamicSections.isEmpty
                  ? const Center(
                      child: SecondaryText(
                        'No se pudieron cargar los intereses',
                        fontSize: 16,
                      ),
                    )
                  : ListView.builder(
                      itemCount: dynamicSections.length,
                      itemBuilder: (context, index) {
                        final section = dynamicSections[index];
                        return _buildSection(section, index);
                      },
                    ),
            ),

            const SizedBox(height: 40),
            // Botones
            userDetailsButton(
              controller: widget.controller,
              context: context,
              action: UserDetailsAction.finalRegister,
              onFinalAction: () => _updateCubit(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(InterestSectionModel section, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(151, 84, 31, 208),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(170, 95, 27, 255),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header clickable
          GestureDetector(
            onTap: () => _toggleSection(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 2),
              child: SecondaryText(
                section.title,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),

          // Contenido expandible
          if (section.expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: section.options.map((opt) {
                  final selected = selectedInterests.contains(opt);
                  return _optionButton(
                    opt,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          selectedInterests.remove(opt);
                        } else {
                          selectedInterests.add(opt);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionButton(
    String label, {
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        gradient: selected
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [AppColors.secondaryText, AppColors.secondaryText],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap,
        child: SecondaryText(
          label,
          color: AppColors.backgroundDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
