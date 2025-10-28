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
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/registration_handler.dart';
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
  List<InterestSectionModel> dynamicSections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
    _initializeSelectedInterests();
  }

  /// 🔹 Inicializar intereses seleccionados según el modo
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

      // Convertir el mapa a un Set de intereses individuales
      setState(() {
        selectedInterests = existingInterests.values
            .expand((list) => list)
            .toSet();
      });
    });
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

  /// 🔹 Actualizar el cubit correspondiente
  void _updateCubit(Map<String, List<String>> selectedBySection) {
    if (widget.mode == MoreUserDetailsMode.register) {
      context.read<RegisterCubit>().setInterests(selectedBySection);
    } else {
      context.read<EditCubit>().updateInterests(selectedBySection);
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
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  /// 🔹 Construir botón de acción según el modo
  Widget _buildActionButton() {
    if (widget.mode == MoreUserDetailsMode.register) {
      // En modo registro, usar el botón original con registration_handler
      return userDetailsButton(
        controller: widget.controller,
        context: context,
        action: UserDetailsAction.finalRegister,
        onFinalAction: () async {
          final registerCubit = context.read<RegisterCubit>();
          final authCubit = context.read<AuthCubit>();

          // Construir intereses por sección
          final selectedBySection = <String, List<String>>{};
          for (final section in dynamicSections) {
            final picked = section.options
                .where((o) => selectedInterests.contains(o))
                .toList();
            if (picked.isNotEmpty) {
              selectedBySection[section.title] = picked;
            }
          }

          // Llamar al handler centralizado
          try {
            await RegistrationHandler.completeRegistration(
              context: context,
              registerCubit: registerCubit,
              authCubit: authCubit,
              selectedInterests: selectedBySection,
            );
          } catch (e) {
            debugPrint('❌ [InterestsStep] Error en completeRegistration: $e');
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              LoadingOverlay.hide(context);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error completando registro: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    } else {
      // En modo edición, simplemente guardar y volver
      return ElevatedButton(
        onPressed: () {
          // Construir intereses por sección y actualizar el cubit
          final selectedBySection = <String, List<String>>{};
          for (final section in dynamicSections) {
            final picked = section.options
                .where((o) => selectedInterests.contains(o))
                .toList();
            if (picked.isNotEmpty) {
              selectedBySection[section.title] = picked;
            }
          }

          _updateCubit(selectedBySection);

          // Volver (el guardado se hará desde MoreUserDetails con el botón Save)
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Done'),
      );
    }
  }

  Widget _buildSection(InterestSectionModel section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

                  // 🔹 Actualizar el cubit en tiempo real
                  final selectedBySection = <String, List<String>>{};
                  for (final sec in dynamicSections) {
                    final picked = sec.options
                        .where((o) => selectedInterests.contains(o))
                        .toList();
                    if (picked.isNotEmpty) {
                      selectedBySection[sec.title] = picked;
                    }
                  }
                  _updateCubit(selectedBySection);
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
