import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Embed video section — YouTube video with cover image.
/// Mirrors the React EmbedVideo component.
/// On Flutter web, opens the video in a new tab when tapped.
class EmbedVideoSection extends StatelessWidget {
  const EmbedVideoSection({super.key});

  String _getVideoUrl(BuildContext context) {
    final locale = context.locale.languageCode;
    final videoId = locale.startsWith('es') ? 'JVuqUGGWDy8' : 'VAvOH0GCB2Y';
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  Future<void> _openVideo(BuildContext context) async {
    final url = Uri.parse(_getVideoUrl(context));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5, // 50vh — video section
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/landing/backgroundSectionOne.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildCoverImage(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openVideo(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/landing/video.webp', fit: BoxFit.cover),
            // Play button overlay
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
