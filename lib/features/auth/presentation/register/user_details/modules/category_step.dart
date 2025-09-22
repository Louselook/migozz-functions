import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/down_buttons.dart';

// Cambiar

class CategoryStep extends StatefulWidget {
  final PageController controller;
  const CategoryStep({super.key, required this.controller});

  @override
  State<CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<CategoryStep> {
  List<String> selectedCategories = [];

  final List<String> categories = [
    'Influencer',
    'Artist',
    'Streamer',
    'Model',
    'Public Figure',
  ];

  @override
  Widget build(BuildContext context) {
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
                  return _categoryButton(
                    category,
                    selected: selectedCategories.contains(category),
                    onTap: () {
                      setState(() {
                        if (selectedCategories.contains(category)) {
                          selectedCategories.remove(category);
                        } else {
                          selectedCategories.add(category);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Botones
            downButtons(controller: widget.controller),
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
