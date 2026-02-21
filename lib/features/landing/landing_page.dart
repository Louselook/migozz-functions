import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
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
    );
  }
}
