import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Welcome section — "YOUR FIRST AI ECOSYSTEM" with phone screenshots background.
/// Updated design inspired by landing_page2.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  static const _bgColor = Color(0xFF0D0D0D);
  static const _hotPink = Color(0xFFE91E8B);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      color: _bgColor,
      child: Stack(
        children: [
          // Phone screenshots background — fills entire section edge-to-edge
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/images/landing/Migozz_background_phone.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Content with padding on top of bg
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 40 : 64,
              horizontal: isMobile ? 16 : 48,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTitle(isMobile),
                  const SizedBox(height: 20),
                  _buildSubtitle(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isMobile) {
    final parts = 'landing.welcome_title'.tr().split('|');
    final mainText = parts.isNotEmpty ? parts[0] : '';
    final highlightText = parts.length > 1 ? parts[1] : '';

    return Column(
      children: [
        Text(
          mainText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 26 : 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Bebas Neue',
          ),
        ),
        if (highlightText.isNotEmpty)
          Text(
            highlightText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 44,
              fontWeight: FontWeight.w900,
              color: _hotPink,
              fontFamily: 'Bebas Neue',
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Text(
        'landing.welcome_subtitle'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          color: Colors.white70,
          fontFamily: 'Bebas Neue',
          height: 1.7,
        ),
      ),
    );
  }
}
