import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFakeData(); //// Aca hay que carga los datos reales
  }

  void _loadFakeData() {
    sections = [
      InterestSectionModel(
        title: "Going Out",
        options: [
          "Concerts",
          "Museum & Galleries",
          "Yoga",
          "Comedy",
          "Theater",
          "Clubs",
          "Bars",
          "Karaoke",
          "Film Festivals",
          "Lounging"
        ],
        expanded: true,
      ),
      InterestSectionModel(
        title: "Sports",
        options: [
          "Football",
          "Soccer",
          "Hockey",
          "Sports News",
          "Fishing",
          "Basquetball",
          "Cricket",
          "Pickleball",
          "Gymnastia",
          "Horse Riding",
          "MMA",
          "Tennis",
          "Swimming",
          "Snowboarding",
          "Gym",
          "Surfing",
          "Skiing",
          "Baseball",
          "Golf",
          "Boxing"
        ],
        expanded: true,
      ),
      InterestSectionModel(
        title: "Film & Tv",
        options: [
          "Drama",
          "Thriller",
          "Crime",
          "Fantasy",
          "Anime",
          "Sci-fi",
          "Mistery",
          "Comedy",
          "Romance",
        ],
        expanded: true,
      ),
    ];
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
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildSection(section);
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
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 18),
                    ),
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

  Widget _buildSection(InterestSectionModel section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con el botón "+"
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            SecondaryText(section.title, fontSize: 18),
          ],
        ),
        const SizedBox(height: 8),

        // Opciones en chips
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
                    horizontal: 14, vertical: 8),
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
                      const Icon(Icons.check,
                          size: 16, color: Colors.green),
                    if (selected) const SizedBox(width: 4),
                    Text(
                      opt,
                      style: TextStyle(
                        color: selected
                            ? Colors.green
                            : AppColors.backgroundDark,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
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
