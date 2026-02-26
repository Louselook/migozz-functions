import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';

class ListenMusicScreenWeb extends StatelessWidget {
  const ListenMusicScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileWidth = size.width < 600;
    final isMenuMedium = size.width >= 600 && size.width < 1200;
    final leftMenuWidth = isMobileWidth ? 60.0 : (isMenuMedium ? 70.0 : 80.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Row(
              children: [
                if (!isMobileWidth) SizedBox(width: leftMenuWidth),
                Expanded(
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Bar / Back button Placeholder
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (context.canPop())
                                          context.pop();
                                        else
                                          context.go('/profile');
                                      },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 10),

                                      // Album Image
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          child: Image.asset(
                                            'assets/images/AlbumImage.webp',
                                            fit: BoxFit.cover,
                                            width: isMobileWidth
                                                ? (size.width - 80)
                                                : 340,
                                            height: isMobileWidth
                                                ? (size.width - 80)
                                                : 340,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: isMobileWidth
                                                        ? (size.width - 80)
                                                        : 340,
                                                    height: isMobileWidth
                                                        ? (size.width - 80)
                                                        : 340,
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
                                          color: Color(
                                            0xFFD320A7,
                                          ), // Magenta/Pink
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 30),

                                      // White Card
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 30,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                          horizontal: 10,
                                        ),
                                        constraints: const BoxConstraints(
                                          maxWidth: 420,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Apple Music
                                            _PlatformTile(
                                              leading: SvgPicture.asset(
                                                'assets/icons/social_networks/AppleMusic.svg',
                                                width: 32,
                                                height: 32,
                                                placeholderBuilder: (_) =>
                                                    const Icon(
                                                      Icons.music_note,
                                                      color: Colors.red,
                                                      size: 32,
                                                    ),
                                              ),
                                              titleWidget: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Pre-add on',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Apple Music',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              button: const _ActionBtn(
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
                                                  color: const Color(
                                                    0xFF1CB7D0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
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
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              button: const _ActionBtn(
                                                text: 'Play',
                                              ),
                                            ),

                                            const SizedBox(height: 16),

                                            // Spotify
                                            _PlatformTile(
                                              leading: SvgPicture.asset(
                                                'assets/icons/social_networks/Spotify.svg',
                                                width: 32,
                                                height: 32,
                                                placeholderBuilder: (_) =>
                                                    const Icon(
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
                                              button: const _ActionBtn(
                                                text: 'Play',
                                              ),
                                            ),

                                            const SizedBox(height: 16),

                                            // YouTube Premium
                                            _PlatformTile(
                                              leading: SvgPicture.asset(
                                                'assets/icons/social_networks/Youtube.svg',
                                                width: 32,
                                                height: 32,
                                                placeholderBuilder: (_) =>
                                                    const Icon(
                                                      Icons.play_circle,
                                                      color: Colors.red,
                                                      size: 32,
                                                    ),
                                              ),
                                              titleWidget: const Text(
                                                'Premium',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              button: const _ActionBtn(
                                                text: 'Play',
                                              ),
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isMobileWidth)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: leftMenuWidth,
              child: SideMenu(tutorialKeys: TutorialKeys()),
            ),
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final Widget leading;
  final Widget titleWidget;
  final Widget button;

  const _PlatformTile({
    required this.leading,
    required this.titleWidget,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: titleWidget),
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
      width: 85,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.grey[200],
        gradient: isGradient
            ? const LinearGradient(
                colors: [Color(0xFFECA376), Color(0xFFA140B4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFE5E5E5), Color(0xFFF2F2F2)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isGradient ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
