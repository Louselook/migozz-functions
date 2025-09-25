import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/const_sctions.dart';
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

  void _updateCubit() {
    final cubit = context.read<RegisterCubit>();

    // Agrupar intereses por sección
    final Map<String, List<String>> interestsBySection = {};
    for (var section in sections) {
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
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
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
        gradient: selected
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [AppColors.secondaryText, AppColors.secondaryText],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap, // ahora sí usa el callback
        child: SecondaryText(
          label,
          color: AppColors.backgroundDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
