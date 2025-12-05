import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/interest_section_model.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen>
    with TickerProviderStateMixin {
  Set<String> selectedInterests = {};
  List<InterestSectionModel> sections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
  }

  Future<void> fetchCollection() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Cargar catálogo
      final catalogSnapshot = await FirebaseFirestore.instance
          .collection('interests_catalog')
          .get();

      final List<InterestSectionModel> fetchedSections = [];
      for (var doc in catalogSnapshot.docs) {
        final data = doc.data();
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

      // Obtener UID actual
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user logged in');
        setState(() {
          sections = fetchedSections;
          isLoading = false;
        });
        return;
      }

      // Cargar intereses del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();
      final userInterests =
          userData?['interests'] as Map<String, dynamic>? ?? {};

      // Convertir el mapa a un set plano
      final selected = userInterests.values
          .expand((value) => List<String>.from(value))
          .toSet();

      // Expandir las secciones donde el usuario tenga algo seleccionado
      for (final section in fetchedSections) {
        if (userInterests[section.title] != null) {
          section.expanded = true;
        }
      }

      // Actualizar el estado
      setState(() {
        sections = fetchedSections;
        selectedInterests = selected;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading interests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // helper para actualizar Firestore (llamado al guardar)
  Future<void> _saveInterests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    final selectedBySection = <String, List<String>>{};
    for (final section in sections) {
      final picked = section.options
          .where((o) => selectedInterests.contains(o))
          .toList();
      if (picked.isNotEmpty) {
        selectedBySection[section.title] = picked;
      }
    }

    try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'interests': selectedBySection});
        if (context.mounted) {
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interests saved successfully')),
          );
          Navigator.pop(context, "done");
        }
      }
    } catch (e) {
      if(mounted){ 
        debugPrint('Error saving interests: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving interests')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Edit my Interest",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            return _buildSection(section, index);
                          },
                        ),
                      ),
              ),

              // Save button (gradient)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveInterests,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 6),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Text("Save", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              section.expanded = !section.expanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // botón redondo con imagen (placeholder). Reemplazá el asset por tu PNG.
                GestureDetector(
                  onTap: () {
                    setState(() {
                      section.expanded = !section.expanded;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      shape: BoxShape.circle,
                      // pequeño borde para que se note sobre el fondo
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/Migozz_Icon.svg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, err, stack) =>
                            Icon(section.expanded ? Icons.expand_less : Icons.add,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SecondaryText(section.title, fontSize: 18),
                const Spacer(),
                if (section.options.any((o) => selectedInterests.contains(o)))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        ),

        // Animated expand/collapse con fade + size
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: section.expanded
                ? Padding(
                    key: ValueKey('expanded_$index'),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: LayoutBuilder(builder: (context, constraints) {
                      // Grid de 4 columnas. Ajusté childAspectRatio para campos más grandes.
                      return GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.4,
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
                            },
                          );
                        }).toList(),
                      );
                    }),
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
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
    // estilos según mock: fondo gris oscuro, texto blanco; borde cambia al seleccionar
    final bgColor = const Color(0xFF1E1E1E); // gris muy oscuro para los fields
    final borderColor = selected ? const Color(0xFFB646F6) : Colors.transparent;
    final textColor = Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6), // muy poco redondeado
        border: Border.all(width: 2, color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11, // texto un poco más pequeño
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
