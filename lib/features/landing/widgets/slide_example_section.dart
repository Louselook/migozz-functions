import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Slide example section — 3 feature cards with vertical phone images.
/// Updated design inspired by landing_page2.
class SlideExampleSection extends StatelessWidget {
  const SlideExampleSection({super.key});

  static const _hotPink = Color(0xFFE91E8B);
  static const _purple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 750;

    final features = [
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_1.png',
        title: 'landing.slide_1_title'.tr(),
        description: 'landing.slide_1_text'.tr(),
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_2.png',
        title: 'landing.slide_2_title'.tr(),
        description: 'landing.slide_2_text'.tr(),
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_3.png',
        title: 'landing.slide_3_title'.tr(),
        description: 'landing.slide_3_text'.tr(),
      ),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child: Stack(
        children: [
          // Decorative Migozz icon — one on each side
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(_purple, BlendMode.srcATop),
                child: Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/landing/MigozzVector.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: Image.asset(
                        'assets/images/landing/MigozzVector.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Actual content
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 32 : 48,
              horizontal: isMobile ? 16 : 48,
            ),
            child: Column(
              children: features
                  .map((f) => _buildFeatureCard(f, isMobile))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isMobile) {
    final imageWidget = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? 220 : 380,
        maxHeight: isMobile ? 300 : 520,
      ),
      child: Image.asset(
        feature.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(Icons.phone_android, size: 64, color: Colors.grey),
          ),
        ),
      ),
    );

    final textWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_hotPink, _purple],
            ).createShader(bounds),
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: isMobile ? 25 : 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Bebas Neue',
                height: 1.3,
              ),
            ),
          ),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              color: Colors.black87,
              fontFamily: 'Bebas Neue',
              height: 1.6,
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [imageWidget, const SizedBox(height: 20), textWidget],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          imageWidget,
          const SizedBox(width: 40),
          Flexible(child: textWidget),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String imagePath;
  final String title;
  final String description;

  const _FeatureItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
