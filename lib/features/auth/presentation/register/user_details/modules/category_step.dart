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
  String? selectedCategory;
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
  /**
 * Estructura Firebase:
 * name -> string
 * status: string (active, inactive)
 * Solo se muestran las categorías con status: "active"
 */

  @override
  Widget build(BuildContext context) {
    // final cubit = context.read<RegisterCubit>();

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
                    const spacing = 16.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;

                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
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
                              final isSelected = selectedCategory == category;
                              return SizedBox(
                                width: itemWidth,
                                child: _categoryButton(
                                  category,
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                    // cubit.setCategory(category);
                                    // debugPrint(
                                    //   "🏷️ Categoria seleccionada: ${cubit.state.category}",
                                    // );
                                  },
                                ),
                              );
                            }).toList(),
                    );
                  },
                ),
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
    return SizedBox(
      height: 56, // altura consistente
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: AppColors.primaryGradient.colors)
                : LinearGradient(colors: AppColors.primaryGradient.colors),
            color: selected ? null : AppColors.backgroundGoole.withOpacity(0.4),
            border: Border.all(
              color: selected
                  ? const Color.fromARGB(255, 96, 27, 255)
                  : AppColors.backgroundGoole,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SecondaryText(label, fontSize: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
