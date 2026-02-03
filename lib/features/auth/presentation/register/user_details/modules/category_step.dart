import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

class CategoryStep extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;

  const CategoryStep({
    super.key,
    required this.controller,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<CategoryStep> createState() => _CategoryStepState();
}

class _CategoryStepState extends State<CategoryStep> {
  static const int maxCategories = 2;
  List<String> selectedCategories = [];
  List<String> dynamicCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Cargar datos de Firebase al inicializar la vista
    fetchCollection();
    // Inicializar categorías seleccionadas según el modo
    _initializeSelectedCategories();
  }

  // Inicializar categorías seleccionadas según el modo
  void _initializeSelectedCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == MoreUserDetailsMode.register) {
        final registerState = context.read<RegisterCubit>().state;
        setState(() {
          selectedCategories = List<String>.from(
            registerState.category ?? const <String>[],
          );
        });
      } else {
        final editState = context.read<EditCubit>().state;
        setState(() {
          selectedCategories = List<String>.from(
            editState.category ?? const <String>[],
          );
        });
      }
    });
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

  // Actualizar el cubit correspondiente según el modo
  void _updateCubit() {
    if (widget.mode == MoreUserDetailsMode.register) {
      context.read<RegisterCubit>().setCategories(
        List<String>.from(selectedCategories),
      );
    } else {
      context.read<EditCubit>().updateCategory(
        List<String>.from(selectedCategories),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.backgroundDark)),
          const Positioned.fill(
            child: TintesGradients(child: SizedBox.expand()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 10),
                PrimaryText('category.title'.tr()),
                const SizedBox(height: 8),
                SecondaryText(
                  'category.subtitle'.tr(),
                  fontSize: 14,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : dynamicCategories.isEmpty
                      ? const Center(
                          child: SecondaryText(
                            'No hay categorías disponibles',
                            fontSize: 16,
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 3.2,
                              ),
                          itemCount: dynamicCategories.length,
                          itemBuilder: (context, index) {
                            final category = dynamicCategories[index];
                            final isSelected = selectedCategories.contains(
                              category,
                            );

                            return _categoryButton(
                              category,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (selectedCategories.contains(category)) {
                                    selectedCategories.remove(category);
                                  } else {
                                    if (selectedCategories.length >=
                                        maxCategories) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'category.maxSelection'.tr(),
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    selectedCategories.add(category);
                                  }
                                });

                                _updateCubit();
                                debugPrint(
                                  '🏷️ Categorías seleccionadas: $selectedCategories',
                                );
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: widget.mode == MoreUserDetailsMode.register
                      // En modo registro (desde chat), cerrar pantalla y volver al chat
                      ? GradientButton(
                          width: double.infinity,
                          radius: 19,
                          onPressed: () {
                            _updateCubit();
                            Navigator.of(context).pop('done');
                          },
                          child: const SecondaryText('Continue', fontSize: 20),
                        )
                      // En modo edición, ir a la siguiente página
                      : userDetailsButton(
                          controller: widget.controller,
                          context: context,
                          action: UserDetailsAction.next,
                          mode: widget.mode,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryButton(
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(8));
    final tileColor = Color.lerp(
      AppColors.greyBackground,
      AppColors.backgroundDark,
      0.55,
    )!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: selected
            ? BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: borderRadius,
              )
            : BoxDecoration(
                color: tileColor,
                borderRadius: borderRadius,
                border: Border.all(
                  color: tileColor.withValues(alpha: 0.9),
                  width: 1.5,
                ),
              ),
        padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SecondaryText(label, fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
