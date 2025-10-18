import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
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
              onFinalAction: () async {
                final registerCubit = context.read<RegisterCubit>();
                final authCubit = context.read<AuthCubit>();

                // Construir intereses
                final selectedBySection = <String, List<String>>{};
                for (final section in dynamicSections) {
                  final picked = section.options
                      .where((o) => selectedInterests.contains(o))
                      .toList();
                  if (picked.isNotEmpty) {
                    selectedBySection[section.title] = picked;
                  }
                }

                registerCubit.setInterests(selectedBySection);
                await registerCubit.checkCompletion();

                // Si está completo, registrar usuario
                if (registerCubit.state.isComplete) {
                  try {
                    // ignore: use_build_context_synchronously
                    LoadingOverlay.show(context);
                    await authCubit.completeRegistration(
                      email: registerCubit.state.email!,
                      otp: registerCubit.state.currentOTP!,
                      userData: registerCubit.state.buildUserDTO(),
                    );
                    //  Reiniciar el estado del RegisterCubit
                    registerCubit.reset();
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    LoadingOverlay.hide(context);
                    debugPrint('❌ Error finalizando registro: $e');
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error completando registro: $e')),
                    );
                  }
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Faltan datos para completar el registro'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(InterestSectionModel section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección (clickeable)
        GestureDetector(
          onTap: () {
            setState(() {
              section.expanded = !section.expanded;
            });
          },
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  section.expanded ? Icons.arrow_drop_down_outlined : Icons.add,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 7),
              SecondaryText(section.title, fontSize: 18),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Contenido expandible
        if (section.expanded)
          Wrap(
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

        const SizedBox(height: 20),
      ],
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
        color: AppColors.secondaryText,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            SecondaryText(
              label,
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
