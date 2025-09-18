import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/register/user_details/components/down_buttons.dart';
import 'package:migozz_app/features/register/user_details/components/interest_section_model.dart';

class InterestsStep extends StatefulWidget {
  final PageController controller;
  const InterestsStep({super.key, required this.controller});

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  final List<InterestSectionModel> sections = [
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
        "Lounging",
      ],
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
        "Boxing",
      ],
    ),
    InterestSectionModel(
      title: "Film & Tv",
      options: ["Drama", "Thriller", "Crime"],
    ),
  ];

  Set<String> selectedInterests = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText('Choose Your Interest'),
            const SizedBox(height: 20),

            // secciones
            Expanded(
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildSection(section, index);
                },
              ),
            ),

            const SizedBox(height: 40),
            // Botones
            downButtons(controller: widget.controller),
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
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  section.expanded ? Icons.arrow_drop_down_outlined : Icons.add,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 7),
              SecondaryText(section.title, fontSize: 18),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Contenido expandible
        if (section.expanded)
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: section.options.map((opt) {
              final selected = selectedInterests.contains(opt);
              return _optionButton(
                opt,
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
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _optionButton(
    String label, {
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        gradient: selected
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [AppColors.secondaryText, AppColors.secondaryText],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap, // 👈 ahora sí usa el callback
        child: SecondaryText(
          label,
          color: AppColors.backgroundDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
