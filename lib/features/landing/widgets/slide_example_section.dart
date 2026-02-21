import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Slide example section — 3 feature cards with images.
/// Mirrors the React SlideExample component.
class SlideExampleSection extends StatelessWidget {
  const SlideExampleSection({super.key});

  static const _exampleImages = [
    'assets/images/landing/ExampleOne.webp',
    'assets/images/landing/ExampleThree.webp',
    'assets/images/landing/ExampleTwo.webp',
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    final titles = [
      'landing.slide_1_title'.tr(),
      'landing.slide_2_title'.tr(),
      'landing.slide_3_title'.tr(),
    ];
    final texts = [
      'landing.slide_1_text'.tr(),
      'landing.slide_2_text'.tr(),
      'landing.slide_3_text'.tr(),
    ];

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: screenHeight, // 100vh
      ),
      color: const Color(0xFFF3F4F6),
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: i < 2 ? 60 : 0),
                      child: _buildCard(titles[i], texts[i], _exampleImages[i]),
                    ),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: i == 1 ? 20 : 0,
                        ),
                        child: _buildCard(
                          titles[i],
                          texts[i],
                          _exampleImages[i],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String text, String imagePath) {
    return Column(
      children: [
        // Image with hover-like shadow
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        // Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
          ).createShader(bounds),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Oswald',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
