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

/// Modelo para representar un grupo de identidades
class IdentityGroup {
  final String id;
  final String name;
  final int order;
  final List<Identity> identities;

  IdentityGroup({
    required this.id,
    required this.name,
    required this.order,
    required this.identities,
  });
}

/// Modelo para representar una identidad
class Identity {
  final String id;
  final String name;
  final int order;
  final String status;

  Identity({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
  });
}

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
  static const int maxCategories = 1;
  List<String> selectedCategories = [];
  List<IdentityGroup> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSelectedCategories();
    // Llamar fetchIdentitiesCatalog después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchIdentitiesCatalog();
    });
  }

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

  Future<void> fetchIdentitiesCatalog() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;
      final List<Identity> identities = [];

      // Leer todas las categorías desde la colección plana categories_catalog
      final snapshot = await firestore.collection('categories_catalog').get();

      debugPrint('📂 categories_catalog documentos: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('   📝 Doc: ${doc.id} -> $data');

        // Solo agregar categorías activas
        if (data['status'] == 'active') {
          identities.add(
            Identity(
              id: doc.id,
              name: data['name'] ?? '',
              order: data['order'] ?? 0,
              status: data['status'] ?? 'active',
            ),
          );
        }
      }

      // Ordenar localmente por order (si existe) y luego por nombre
      identities.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      final List<IdentityGroup> fetchedGroups = [];
      if (identities.isNotEmpty) {
        fetchedGroups.add(
          IdentityGroup(
            id: 'all',
            name: 'all',
            order: 0,
            identities: identities,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        groups = fetchedGroups;
        isLoading = false;
      });

      debugPrint('✅ Categorías cargadas: ${identities.length}');
    } catch (e) {
      debugPrint('❌ Error al traer identidades: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

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

  void _selectIdentity(String identityId) {
    setState(() {
      if (selectedCategories.contains(identityId)) {
        selectedCategories.remove(identityId);
      } else {
        if (selectedCategories.length >= maxCategories) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('category.maxSelection'.tr()),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        selectedCategories.add(identityId);
      }
    });
    _updateCubit();
    debugPrint('🏷️ Identidades seleccionadas: $selectedCategories');
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                      : groups.isEmpty
                          ? const Center(
                              child: SecondaryText(
                                'No hay categorías disponibles',
                                fontSize: 16,
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 10,
                                        children: [
                                          for (final group in groups)
                                            for (final identity
                                                in group.identities)
                                              _identityButton(
                                                identity.name,
                                                selected: selectedCategories
                                                    .contains(identity.id),
                                                onTap: () =>
                                                    _selectIdentity(
                                                  identity.id,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: widget.mode == MoreUserDetailsMode.register
                      ? GradientButton(
                          width: double.infinity,
                          radius: 19,
                          onPressed: () {
                            _updateCubit();
                            Navigator.of(context).pop('done');
                          },
                          child: const SecondaryText('Continue', fontSize: 20),
                        )
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

  // Ya no usamos secciones desplegables: las categorías se muestran
  // todas juntas en un solo Wrap, similar a intereses.

  Widget _identityButton(
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(16));
    final tileColor = Color.lerp(
      AppColors.greyBackground,
      AppColors.backgroundDark,
      0.55,
    )!;

    return GestureDetector(
      onTap: onTap,
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
                  width: 1,
                ),
              ),
        padding: selected ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/icons/Migozz_Icon.png',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
