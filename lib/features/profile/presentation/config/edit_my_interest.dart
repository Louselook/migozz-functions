import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/interest_section_model.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
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
        sections = fetchedSections;
        isLoading = false;
      });

      // Opcional: cargar intereses seleccionados previamente del cubit
      // ignore: use_build_context_synchronously
      final cubit = context.read<RegisterCubit>();
      final interests = cubit.state.interests;
      if (interests != null) {
        selectedInterests = interests.values.expand((list) => list).toSet();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text(
          "Edit my Interest",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return _buildSection(section, index);
                      },
                    ),
            ),
            // Save button (gradient)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final cubit = context.read<RegisterCubit>();
                  final selectedBySection = <String, List<String>>{};

                  for (final section in sections) {
                    final picked = section.options
                        .where((o) => selectedInterests.contains(o))
                        .toList();
                    if (picked.isNotEmpty) {
                      selectedBySection[section.title] = picked;
                    }
                  }

                  cubit.setInterests(selectedBySection);
                  Navigator.pop(context, "done");
                },
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
    );
  }

  Widget _buildSection(InterestSectionModel section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección (clickeable)
        GestureDetector(
          onTap: () {
            setState(() {
              section.expanded = !section.expanded;
            });
          },
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  section.expanded ? Icons.arrow_drop_down_outlined : Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              SecondaryText(section.title, fontSize: 18),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (section.expanded)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: section.options.map((opt) {
              final selected = selectedInterests.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      selectedInterests.remove(opt);
                    } else {
                      selectedInterests.add(opt);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.green : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                      if (selected) const SizedBox(width: 4),
                      Text(
                        opt,
                        style: TextStyle(
                          color: selected
                              ? Colors.green
                              : AppColors.backgroundDark,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
