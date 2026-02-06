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
  static const int maxCategories = 2;
  List<String> selectedCategories = [];
  List<IdentityGroup> groups = [];
  Set<String> expandedGroups = {};
  bool isLoading = true;

  // Orden de los grupos según el diseño
  static const List<String> groupOrder = [
    'creative_arts',
    'tech_science',
    'education_coaching',
    'health_wellness',
    'service_events',
    'lifestyle_hobbies',
  ];

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

      // Obtener el idioma actual (en o es)
      final lang = context.locale.languageCode == 'es' ? 'es' : 'en';
      debugPrint('🌐 Idioma actual: $lang');

      final firestore = FirebaseFirestore.instance;
      final List<IdentityGroup> fetchedGroups = [];

      // Recorrer los grupos en el orden definido
      for (final groupId in groupOrder) {
        debugPrint('📂 Buscando grupo: $groupId');

        // Obtener las identidades de cada grupo (sin orderBy para evitar índice)
        final identitiesSnapshot = await firestore
            .collection('identities_catalog')
            .doc(lang)
            .collection(groupId)
            .get();

        debugPrint(
          '   📄 Documentos encontrados: ${identitiesSnapshot.docs.length}',
        );

        String groupName = groupId;
        final List<Identity> identities = [];

        for (final doc in identitiesSnapshot.docs) {
          final data = doc.data();
          debugPrint('   📝 Doc: ${doc.id} -> $data');

          // Si es el documento de metadata, obtener el nombre del grupo
          if (doc.id == '_metadata') {
            groupName = data['name'] ?? groupId;
            continue;
          }

          // Solo agregar identidades activas
          if (data['status'] == 'active') {
            identities.add(
              Identity(
                id: data['identity_id'] ?? doc.id,
                name: data['name'] ?? '',
                order: data['order'] ?? 0,
                status: data['status'] ?? 'active',
              ),
            );
          }
        }

        // Ordenar las identidades localmente por order
        identities.sort((a, b) => a.order.compareTo(b.order));

        if (identities.isNotEmpty) {
          fetchedGroups.add(
            IdentityGroup(
              id: groupId,
              name: groupName,
              order: groupOrder.indexOf(groupId),
              identities: identities,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        groups = fetchedGroups;
        // Expandir el primer grupo por defecto
        if (groups.isNotEmpty) {
          expandedGroups.add(groups.first.id);
        }
        isLoading = false;
      });

      debugPrint('✅ Grupos cargados: ${groups.length}');
      for (final group in groups) {
        debugPrint(
          '   📁 ${group.name}: ${group.identities.length} identidades',
        );
      }
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

  void _toggleGroup(String groupId) {
    setState(() {
      if (expandedGroups.contains(groupId)) {
        expandedGroups.remove(groupId);
      } else {
        expandedGroups.add(groupId);
      }
    });
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
              duration: const Duration(seconds: 2),
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
                      : groups.isEmpty
                      ? const Center(
                          child: SecondaryText(
                            'No hay categorías disponibles',
                            fontSize: 16,
                          ),
                        )
                      : ListView.builder(
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return _buildGroupSection(group);
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

  Widget _buildGroupSection(IdentityGroup group) {
    final isExpanded = expandedGroups.contains(group.id);
    // Color del título: rosa si está expandido, gris si está colapsado
    final headerColor = isExpanded ? AppColors.primaryPink : AppColors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isExpanded ? AppColors.primaryPink : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del grupo (clickeable para expandir/colapsar)
            InkWell(
              onTap: () => _toggleGroup(group.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Título con animación de color
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        child: Text(group.name.toUpperCase()),
                      ),
                    ),
                    // Icono con animación de color
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        key: ValueKey(isExpanded),
                        color: headerColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Contenido expandible con animación de arriba hacia abajo
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 3.2,
                            ),
                        itemCount: group.identities.length,
                        itemBuilder: (context, index) {
                          final identity = group.identities[index];
                          final isSelected = selectedCategories.contains(
                            identity.id,
                          );
                          return _identityButton(
                            identity.name,
                            selected: isSelected,
                            onTap: () => _selectIdentity(identity.id),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityButton(
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
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: borderRadius,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/icons/Migozz_Icon.png',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
