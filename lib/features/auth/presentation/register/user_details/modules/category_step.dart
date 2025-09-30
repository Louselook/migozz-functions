import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
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
  List<String> selectedCategories = [];
  List<String> dynamicCategories = [];
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
        'categories_catalog',
      );

      QuerySnapshot snapshot = await collection.get();
      List<String> fetchedCategories = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('ID: ${doc.id}, Datos: $data');

        // Solo agregar categorías que tengan status "active"
        if (data.containsKey('name') &&
            data.containsKey('status') &&
            data['status'] == 'active') {
          fetchedCategories.add(data['name'] as String);
        }
      }

      setState(() {
        dynamicCategories = fetchedCategories;
        isLoading = false;
      });

      debugPrint('✅ Categorías activas cargadas: ${dynamicCategories.length}');
    } catch (e) {
      debugPrint('Error al traer datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

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
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: isLoading
                            ? [const Center(child: CircularProgressIndicator())]
                            : dynamicCategories.isEmpty
                            ? [
                                const Center(
                                  child: SecondaryText(
                                    'No hay categorías disponibles',
                                    fontSize: 16,
                                  ),
                                ),
                              ]
                            : dynamicCategories.map((category) {
                                final isSelected = selectedCategories.contains(
                                  category,
                                );
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth * 0.4,
                                    maxWidth: constraints.maxWidth * 0.9,
                                  ),
                                  child: _categoryButton(
                                    category,
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        if (selectedCategories.contains(
                                          category,
                                        )) {
                                          selectedCategories.remove(category);
                                        } else {
                                          selectedCategories.add(category);
                                        }
                                      });
                                      cubit.setCategories(
                                        selectedCategories,
                                      ); // actualizar cubit
                                      debugPrint(
                                        "🏷️ Categorías seleccionadas: $selectedCategories",
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: userDetailsButton(
                controller: widget.controller,
                context: context,
                action: UserDetailsAction.next,
              ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: AppColors.primaryGradient.colors)
              : LinearGradient(colors: AppColors.primaryGradient.colors),
          border: Border.all(
            color: selected
                ? const Color.fromARGB(255, 96, 27, 255)
                : AppColors.backgroundGoole,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SecondaryText(label, fontSize: 18, color: Colors.white),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
