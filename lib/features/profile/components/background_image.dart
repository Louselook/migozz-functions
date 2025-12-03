import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
// import 'package:migozz_app/features/profile/components/scroll_sheet.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final double minHeaderFraction;
  final String? avatarUrl;
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final String voiceNoteUrl;
  final bool isOwnProfile;
  final String userId;
  final TutorialKeys? tutorialKeys;

  const BackgroundImage({
    super.key,
    required this.child,
    this.minHeaderFraction = 0.4,
    this.avatarUrl,
    this.name = 'John Doe',
    this.displayName = '@johndoe',
    this.comunityCount = '1M',
    this.nameComunity = 'Community',
    this.voiceNoteUrl = '',
    this.isOwnProfile = true,
    this.userId = '',
    this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;
    final bottomPaddingForCard = size.height * 0.15;

    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          bottom: false,
          // Reemplazo temporal sin scroll
          child: _ProfileHeaderDelegate(
            maxHeight: size.height,
            minHeight: size.height * minHeaderFraction,
            bottomPaddingForCard: bottomPaddingForCard,
            avatarUrl: avatarUrl,
            name: name,
            displayName: displayName,
            comunityCount: comunityCount,
            nameComunity: nameComunity,
            voiceNoteUrl: voiceNoteUrl,
            tutorialKeys: tutorialKeys,
            isOwnProfile: isOwnProfile,
            userId: userId,
          ).build(context, 0, false),
        ),

        // Gradiente inferior
        TintesGradients(child: Container(height: bottomGradientHeight)),

        // Overlay de contenido dinámico (botones, acciones, etc.)
        child,
      ],
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final double bottomPaddingForCard;
  final String? avatarUrl;
  final String voiceNoteUrl;
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final bool isOwnProfile;
  final String userId;
  final TutorialKeys? tutorialKeys;

  Future<bool>? _imageHeightFuture;

  _ProfileHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.bottomPaddingForCard,
    this.avatarUrl,
    required this.voiceNoteUrl,
    required this.name,
    required this.displayName,
    required this.comunityCount,
    required this.nameComunity,
    required this.isOwnProfile,
    required this.userId,
    this.tutorialKeys,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.bottomPaddingForCard != bottomPaddingForCard ||
        oldDelegate.avatarUrl != avatarUrl;
  }

  Future<ui.Image?> _getImageFromProvider(
    ImageProvider provider,
    ImageConfiguration config,
  ) {
    final completer = Completer<ui.Image?>();
    final stream = provider.resolve(config);
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        completer.complete(null);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        try {
          stream.removeListener(listener);
        } catch (_) {}
        return null;
      },
    );
  }

  Future<bool> _isImageTallEnough(
    BuildContext context,
    String? avatarUrl, {
    int threshold = 600,
  }) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return false;
    final ImageProvider provider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;
    final config = createLocalImageConfiguration(context);
    final ui.Image? img = await _getImageFromProvider(provider, config);
    if (img == null) return false;
    return img.height > threshold;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    _imageHeightFuture ??= _isImageTallEnough(context, avatarUrl);

    return FutureBuilder<bool>(
      future: _imageHeightFuture,
      builder: (context, snapshot) {
        final bool useFullBackground = snapshot.data ?? false;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              useFullBackground
                  ? _buildFullBackground()
                  : _buildCircleAvatarBackground(context),

              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: bottomPaddingForCard * (1.2 - 0.17 * t),
                      left: 16,
                      right: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                        minHeight: 80,
                        maxHeight: 180,
                      ),
                      child: InfoUserProfile(
                        name: name,
                        displayName: displayName,
                        comunityCount: comunityCount,
                        nameComunity: nameComunity,
                        voiceNoteUrl: voiceNoteUrl,
                        isOwnProfile: isOwnProfile,
                        userId: userId,
                        tutorialKeys: tutorialKeys,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15 + 0.17 * t),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullBackground() {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        1.15,
        0,
        0,
        0,
        0,
        0,
        1.15,
        0,
        0,
        0,
        0,
        0,
        1.25,
        0,
        0,
        0,
        1,
        1,
        2,
        0,
      ]),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                "assets/images/profileBackground.webp",
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              "assets/images/profileBackground.webp",
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildCircleAvatarBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset("assets/images/profileBackground.webp", fit: BoxFit.cover),
        Center(
          child: CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.25,
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : const AssetImage("assets/images/profileBackground.webp")
                      as ImageProvider,
          ),
        ),
      ],
    );
  }
}
