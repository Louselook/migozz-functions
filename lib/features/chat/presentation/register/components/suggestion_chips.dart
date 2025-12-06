import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSelected;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: suggestions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greyBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
