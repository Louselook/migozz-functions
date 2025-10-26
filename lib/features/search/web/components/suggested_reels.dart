import 'package:flutter/material.dart';
import 'package:migozz_app/features/search/web/components/suggestion_card.dart';

class SuggestedReels extends StatelessWidget {
  const SuggestedReels({super.key});

  // Datos simulados para mostrar en las cards
  List<Map<String, dynamic>> get _mockItems {
    final images = [
      'assets/images/onboarding_1.webp',
      'assets/images/onboarding_2.webp',
      'assets/images/onboarding_3.webp',
      'assets/images/ImageUno.webp',
      'assets/images/ImageTwo.webp',
      'assets/images/ImageThree.webp',
    ];

    return List.generate(12, (i) {
      return {
        'image': images[i % images.length],
        'name': [
          'Javier Cole',
          'Logan Reed',
          'Emily Dawson',
          'Eli West',
          'Andre Knox',
        ][i % 5],
        'location': [
          'Miami, FL',
          'Dallas, TX',
          'Portland, OR',
          'Eugene, OR',
          'Tucson, AZ',
        ][i % 5],
        'views': '${(i + 1) * 1}M',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _mockItems;

    final size = MediaQuery.of(context).size;
    final scale = size.width / 375.0;

    // Responsive grid: más columnas en pantallas más grandes
    final crossAxisCount = size.width > 1200
        ? 5
        : (size.width > 900 ? 4 : (size.width > 600 ? 3 : 2));

    final crossAxisSpacing = (6.0 * scale).clamp(4.0, 8.0);
    final mainAxisSpacing = (6.0 * scale).clamp(4.0, 8.0);
    // Aspect ratio más alto para cards más compactas (como en el prototipo)
    final childAspectRatio = 0.7;

    return GridView.builder(
      padding: EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return SuggestionCard(
          image: item['image'] as String,
          name: item['name'] as String,
          location: item['location'] as String,
          views: item['views'] as String,
          scale: scale,
        );
      },
    );
  }
}
