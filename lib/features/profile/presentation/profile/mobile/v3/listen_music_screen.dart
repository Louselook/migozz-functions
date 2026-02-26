import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListenMusicScreen extends StatelessWidget {
  const ListenMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B2B8D), // Purple
                    Colors.black,
                    Colors.black,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar Placeholder
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Album Image
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/AlbumImage.webp',
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width - 80,
                              height: MediaQuery.of(context).size.width - 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: MediaQuery.of(context).size.width - 80,
                                  height:
                                      MediaQuery.of(context).size.width - 80,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Titles
                        const Text(
                          'Katie Angel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Game Over',
                          style: TextStyle(
                            color: Color(0xFFD320A7), // Magenta/Pink
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // White Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              // Apple Music
                              _PlatformTile(
                                leading: SvgPicture.asset(
                                  'assets/icons/social_networks/AppleMusic.svg',
                                  width: 32,
                                  height: 32,
                                  placeholderBuilder: (_) => const Icon(
                                    Icons.music_note,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                                titleWidget: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Pre-add on',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Apple Music',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                button: _ActionBtn(
                                  text: 'Pre-Add',
                                  isGradient: true,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Amazon Music
                              _PlatformTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1CB7D0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.library_music,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                titleWidget: const Text(
                                  'Amazon Music',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                button: const _ActionBtn(text: 'Play'),
                              ),

                              const SizedBox(height: 16),

                              // Spotify
                              _PlatformTile(
                                leading: SvgPicture.asset(
                                  'assets/icons/social_networks/Spotify.svg',
                                  width: 32,
                                  height: 32,
                                  placeholderBuilder: (_) => const Icon(
                                    Icons.music_note,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                ),
                                titleWidget: const Text(
                                  'Spotify',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                button: const _ActionBtn(text: 'Play'),
                              ),

                              const SizedBox(height: 16),

                              // YouTube Premium
                              _PlatformTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/social_networks/Youtube.svg',
                                      width: 24,
                                      height: 24,
                                      placeholderBuilder: (_) => const Icon(
                                        Icons.play_circle,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Premium',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                button: const _ActionBtn(text: 'Play'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final Widget leading;
  final Widget? titleWidget;
  final Widget button;

  const _PlatformTile({
    required this.leading,
    this.titleWidget,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          if (titleWidget != null)
            Expanded(child: titleWidget!)
          else
            const Spacer(),
          button,
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String text;
  final bool isGradient;

  const _ActionBtn({required this.text, this.isGradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.grey[300],
        gradient: isGradient
            ? const LinearGradient(
                colors: [Color(0xFFECA376), Color(0xFFA140B4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isGradient ? Colors.black87 : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
