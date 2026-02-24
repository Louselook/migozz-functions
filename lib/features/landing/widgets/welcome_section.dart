import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Welcome section — "YOUR FIRST AI ECOSYSTEM" with phone screenshots background.
/// Updated design inspired by landing_page2.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  static const _bgColor = Color(0xFF0D0D0D);

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
            fontSize: isMobile ? 43 : 95,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Bebas Neue',
            height: 1.0,
          ),
        ),
        if (highlightText.isNotEmpty)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              highlightText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 52 : 95,
                fontWeight: FontWeight.w900,
                color: Colors.white, // ShaderMask needs white base
                fontFamily: 'Bebas Neue',
                height: 1.0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Text(
        'landing.welcome_subtitle'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isMobile ? 14 : 30,
          color: Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }
}
