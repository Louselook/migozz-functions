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

/// Modelo para representar una identidad/categoría
class Identity {
  final String id;
  final Map<String, String> name; // { en: "...", es: "..." }
  final int order;
  final String status;
  final int iconNumber;

  Identity({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
    required this.iconNumber,
  });

  /// Obtiene el nombre según el idioma actual
  String getLocalizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? id;
  }
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
          // Parsear el campo name que puede ser Map o String
          Map<String, String> nameMap;
          if (data['name'] is Map) {
            nameMap = Map<String, String>.from(
              (data['name'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
          } else {
            // Fallback si es string simple
            nameMap = {
              'en': data['name']?.toString() ?? '',
              'es': data['name']?.toString() ?? '',
            };
          }

          identities.add(
            Identity(
              id: doc.id,
              name: nameMap,
              order: data['order'] ?? 0,
              status: data['status'] ?? 'active',
              iconNumber: data['icon_number'] ?? 0,
            ),
          );
        }
      }

      // Ordenar localmente por order (si existe) y luego por nombre en inglés
      identities.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a
            .getLocalizedName('en')
            .toLowerCase()
            .compareTo(b.getLocalizedName('en').toLowerCase());
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
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
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
    return PopScope(
      // Solo permite cerrar si hay al menos una categoría seleccionada
      canPop: selectedCategories.isNotEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedCategories.isEmpty) {
          // Mostrar mensaje si intenta salir sin seleccionar
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text('category.required'.tr()),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
        }
      },
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: AppColors.backgroundDark)),
            const Positioned.fill(
              child: TintesGradients(child: SizedBox.expand()),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  PrimaryText(
                    'category.title'.tr(),
                    fontSize: 22,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  SecondaryText(
                    'category.subtitle'.tr(),
                    fontSize: 14,
                    color: Colors.grey,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
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
                              final langCode = context.locale.languageCode;
                              final availableHeight = constraints.maxHeight;
                              final availableWidth = constraints.maxWidth;

                              final totalItems = groups.fold<int>(
                                0,
                                // ignore: avoid_types_as_parameter_names
                                (sum, g) => sum + g.identities.length,
                              );

                              // Base: item ~110px ancho, ~42px alto
                              const baseItemWidth = 110.0;
                              const baseItemHeight = 42.0;
                              const baseGap = 8.0;

                              // Cuántos items caben por fila
                              final itemsPerRow =
                                  (availableWidth / (baseItemWidth + baseGap))
                                      .floor()
                                      .clamp(2, 5);
                              final totalRows = (totalItems / itemsPerRow)
                                  .ceil();

                              // Altura necesaria vs disponible
                              final neededHeight =
                                  totalRows * (baseItemHeight + baseGap);
                              final scaleFactor =
                                  (availableHeight / neededHeight).clamp(
                                    0.5,
                                    1.0,
                                  );

                              final horizontalSpacing = 8.0 * scaleFactor;
                              final verticalSpacing = 8.0 * scaleFactor;

                              return Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.spaceEvenly,
                                  spacing: horizontalSpacing,
                                  runSpacing: verticalSpacing,
                                  children: [
                                    for (final group in groups)
                                      for (final identity in group.identities)
                                        _identityButton(
                                          identity.getLocalizedName(langCode),
                                          iconNumber: identity.iconNumber,
                                          selected: selectedCategories.contains(
                                            identity.id,
                                          ),
                                          onTap: () =>
                                              _selectIdentity(identity.id),
                                          scaleFactor: scaleFactor,
                                        ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.01,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                    ),
                    child: widget.mode == MoreUserDetailsMode.register
                        ? GradientButton(
                            width: double.infinity,
                            radius: 19,
                            onPressed: () {
                              if (selectedCategories.isEmpty) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text('category.required'.tr()),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                return;
                              }
                              _updateCubit();
                              Navigator.of(context).pop('done');
                            },
                            child: const SecondaryText(
                              'Continue',
                              fontSize: 20,
                            ),
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
      ),
    );
  }

  // Ya no usamos secciones desplegables: las categorías se muestran
  // todas juntas en un solo Wrap, similar a intereses.

  Widget _identityButton(
    String label, {
    int iconNumber = 0,
    bool selected = false,
    VoidCallback? onTap,
    double scaleFactor = 1.0,
  }) {
    final borderRadius = BorderRadius.all(Radius.circular(20 * scaleFactor));
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
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scaleFactor,
            vertical: 10 * scaleFactor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de la categoría
              if (iconNumber > 0) ...[
                Image.asset(
                  'assets/icons/account_type/$iconNumber.png',
                  width: 22 * scaleFactor,
                  height: 22 * scaleFactor,
                  color: selected ? Colors.white : Colors.white70,
                ),
                SizedBox(width: 6 * scaleFactor),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15 * scaleFactor,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) ...[
                SizedBox(width: 5 * scaleFactor),
    
              ],
            ],
          ),
        ),
      ),
    );
  }
}
