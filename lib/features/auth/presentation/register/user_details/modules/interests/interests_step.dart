import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
// import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/interest_section_model.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/registration_handler.dart';
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

class _InterestsStepState extends State<InterestsStep>
    with TickerProviderStateMixin {
  Set<String> selectedInterests = {};
  List<InterestSectionModel> dynamicSections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
    _initializeSelectedInterests();
  }

  // Inicializar intereses seleccionados según el modo
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
        selectedInterests =
            existingInterests.values.expand((list) => list).toSet();
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

  // Actualizar el cubit correspondiente
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
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.grey[400]),
          thickness: WidgetStateProperty.all(8.0),
          radius: const Radius.circular(10),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        child: Scrollbar(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 680),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          const PrimaryText('Choose Your Interest'),
                          const SizedBox(height: 20),

                          // secciones
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dynamicSections.length,
                            itemBuilder: (context, index) {
                              final section = dynamicSections[index];
                              return _buildSection(section, index);
                            },
                          ),

                          const SizedBox(height: 40),
                          // Botones
                          _buildActionButton(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Construir botón de acción según el modo (ahora con gradient Save para edición)
  Widget _buildActionButton() {
    if (widget.mode == MoreUserDetailsMode.register) {
      // En modo registro, usar el botón original con registration_handler
      return userDetailsButton(
        controller: widget.controller,
        context: context,
        action: UserDetailsAction.finalRegister,
        onFinalAction: () async {
          final selectedBySection = <String, List<String>>{};
          for (final section in dynamicSections) {
            final picked = section.options
                .where((o) => selectedInterests.contains(o))
                .toList();
            if (picked.isNotEmpty) {
              selectedBySection[section.title] = picked;
            }
          }

          // Puedes activar aquí el handler si lo necesitas
        },
      );
    } else {
      // En modo edición, mostrar "Save" con gradiente como en el mock
      return GestureDetector(
        onTap: () {
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

          Navigator.of(context).pop();
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSection(InterestSectionModel section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              section.expanded = !section.expanded;
            });
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  section.expanded ? Icons.arrow_drop_down : Icons.add,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 10),
              SecondaryText(section.title, fontSize: 18),
              const Spacer(),
              // small count of selected in this section
              if (section.options.any((o) => selectedInterests.contains(o)))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SecondaryText(
                    '${section.options.where((o) => selectedInterests.contains(o)).length}',
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Animated size + fade for the content
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: section.expanded
                ? Padding(
                    key: ValueKey('expanded_$index'),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: LayoutBuilder(builder: (context, constraints) {
                      // GridView con 4 columnas. Ajusta childAspectRatio si hace falta
                      return GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 3.0,
                        children: section.options.map((opt) {
                          final selected = selectedInterests.contains(opt);
                          return _optionGridItem(
                            label: opt,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  selectedInterests.remove(opt);
                                } else {
                                  selectedInterests.add(opt);
                                }
                              });

                              // Actualizar el cubit en tiempo real
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
                      );
                    }),
                  )
                : const SizedBox.shrink(
                    key: ValueKey('collapsed'),
                  ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _optionGridItem({
    required String label,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    // Colores para el borde cuando está seleccionado
    final borderColor = selected ? const Color(0xFFB646F6) : Colors.transparent;
    final innerBg = AppColors.secondaryText;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 2, color: borderColor),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFB646F6).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: innerBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // check marker
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: selected
                      ? Container(
                          key: const ValueKey('check'),
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 12),
                        )
                      : SizedBox(key: const ValueKey('empty'), width: 0),
                ),
                Flexible(
                  child: SecondaryText(
                    label,
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w500,
                    // maxLines: 1,
                    // overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
