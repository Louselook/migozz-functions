// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional imports for web
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Embed video section — YouTube video embedded inline (web) or cover image (mobile).
/// Full-width design matching landing_page2 style.
///
/// - Shows a thumbnail + play button; click starts the video.
/// - pointer-events: none on iframe so page scroll is never blocked.
class EmbedVideoSection extends StatefulWidget {
  const EmbedVideoSection({super.key});

  @override
  State<EmbedVideoSection> createState() => _EmbedVideoSectionState();
}

class _EmbedVideoSectionState extends State<EmbedVideoSection> {
  late final String _viewId;
  bool _iframeRegistered = false;
  html.IFrameElement? _iframe;
  bool _isPlaying = false;

  String _getVideoId(BuildContext context) {
    final locale = context.locale.languageCode;
    return locale.startsWith('es') ? 'JVuqUGGWDy8' : 'VAvOH0GCB2Y';
  }

  void _registerIframe(String videoId) {
    if (_iframeRegistered) return;
    _viewId = 'youtube-embed-${Random().nextInt(999999)}';

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      _iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents =
            'none' // ← allows page scroll over the video
        ..allowFullscreen = true
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
      return _iframe!;
    });
    _iframeRegistered = true;
  }

  void _playVideo(String videoId) {
    if (_isPlaying) return;
    // Set the src with autoplay so it starts immediately on click
    _iframe?.src =
        'https://www.youtube.com/embed/$videoId'
        '?rel=0&modestbranding=1&playsinline=1'
        '&autoplay=1&enablejsapi=1';
    setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _getVideoId(context);

    if (kIsWeb) {
      _registerIframe(videoId);
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Video iframe (pointer-events: none — scroll always works)
              Positioned.fill(child: HtmlElementView(viewType: _viewId)),

              // Thumbnail + play button overlay (hidden once playing)
              if (!_isPlaying)
                Positioned.fill(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _playVideo(videoId),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // YouTube max-res thumbnail
                          Image.network(
                            'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.black),
                          ),
                          // Subtle dark scrim
                          Container(color: Colors.black.withValues(alpha: 0.3)),
                          // Play button
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.shade700,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Fallback for non-web: cover image that opens YouTube
    return _buildCoverFallback(context, videoId);
  }

  Widget _buildCoverFallback(BuildContext context, String videoId) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/landing/video.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
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
        ),
      ),
    );
  }
}
