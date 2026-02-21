import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Welcome section — "YOUR FIRST AI ECOSYSTEM" with background image.
/// Mirrors the React Welcome component.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5, // 50vh like React original
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/landing/fondoHome.webp'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        color: Colors.black,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title with highlight
              _buildTitle(isMobile),
              const SizedBox(height: 32),
              // Subtitle
              _buildSubtitle(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isMobile) {
    // Parse the title to handle the highlight span
    // Original: "YOUR FIRST AI<br /><span class="highlight">ECOSYSTEM</span>"
    // We'll split into two parts
    final titleParts = 'landing.welcome_title'.tr().split('|');
    final mainText = titleParts.isNotEmpty ? titleParts[0] : '';
    final highlightText = titleParts.length > 1 ? titleParts[1] : '';

    return Column(
      children: [
        Text(
          mainText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: isMobile ? 32 : 96,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 0.9,
            letterSpacing: 1,
          ),
        ),
        if (highlightText.isNotEmpty)
          Text(
            highlightText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: isMobile ? 32 : 96,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD43AB6),
              height: 0.9,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Text(
        'landing.welcome_subtitle'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isMobile ? 16 : 24,
          color: const Color(0xFFE0E0E0),
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
