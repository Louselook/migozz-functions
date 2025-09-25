import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';

class CategoryStep extends StatefulWidget {
  final PageController controller;
  const CategoryStep({super.key, required this.controller});

  @override
  State<CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<CategoryStep> {
  String? selectedCategory;

  final List<String> categories = [
    'Influencer',
    'Artist',
    'Streamer',
    'Model',
    'Public Figure',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterCubit>();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText('Choose Your Category'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return _categoryButton(
                    category,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        // Actualizar el cubit al seleccionar
                        cubit.setCategory(category);
                        debugPrint(
                          "🏷️ Categoria seleccionada: ${cubit.state.category}",
                        );
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Botones de navegación
            userDetailsButton(
              controller: widget.controller,
              context: context,
              action: UserDetailsAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryButton(
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundGoole.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SecondaryText(label, fontSize: 16),
            Container(
              child: selected
                  ? const CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 15,
                      child: Icon(
                        Icons.check,
                        color: AppColors.backgroundLight,
                        size: 20,
                      ),
                    )
                  : GradientButton(
                      width: 30,
                      height: 30,
                      radius: 5,
                      onPressed: onTap,
                      child: const Icon(Icons.add, color: AppColors.textLight),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
