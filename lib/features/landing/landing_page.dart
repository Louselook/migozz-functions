import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/join_migozz_section.dart';
import 'widgets/embed_video_section.dart';
import 'widgets/welcome_section.dart';
import 'widgets/slide_example_section.dart';
import 'widgets/more_info_section.dart';
import 'widgets/social_networks_footer.dart';

/// Landing page shown only for web users who are not authenticated.
/// Fully functional — migrated from the React LandingMigozz project.
/// Uses the same API endpoints (API_MIGOZZ) for pre-registration.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: const [
                JoinMigozzSection(),
                EmbedVideoSection(),
                WelcomeSection(),
                SlideExampleSection(),
                MoreInfoSection(),
                SocialNetworksFooter(),
              ],
            ),
          ),
          // Floating "Log in" button — bottom-right corner
          Positioned(
            right: 16,
            bottom: 24,
            child: _LoginFloatingButton(onTap: () => context.go('/onboarding')),
          ),
        ],
      ),
    );
  }
}

/// Floating button that mimics the design in the reference image:
/// orange-to-red gradient, "Have an account?" label + bold "Log in".
class _LoginFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginFloatingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Have an\naccount?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Log in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
