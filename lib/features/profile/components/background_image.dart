import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/scroll_sheet.dart';
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
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileHeaderDelegate(
                    maxHeight: size.height,
                    minHeight: size.height * minHeaderFraction,
                    bottomPaddingForCard: bottomPaddingForCard,
                    avatarUrl: avatarUrl,
                    name: name,
                    displayName: displayName,
                    comunityCount: comunityCount,
                    nameComunity: nameComunity,
                    voiceNoteUrl: voiceNoteUrl,
                    tutorialKeys: tutorialKeys, // ✅ Pasar aquí
                  ),
                ),
              ];
            },
            body: buildProfileCardsGrid(
              context,
              count: 30,
              onTap: (i) => debugPrint("Card $i tocada"),
              bottomExtraPadding: bottomGradientHeight,
            ),
          ),
        ),

        TintesGradients(child: Container(height: bottomGradientHeight)),
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
  final TutorialKeys? tutorialKeys; // ✅ Agregar aquí

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
    this.tutorialKeys, // ✅ Agregar aquí
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.bottomPaddingForCard != bottomPaddingForCard;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
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
                    key: ValueKey<String>(avatarUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      "assets/images/profileBackground.jpg",
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    "assets/images/profileBackground.jpg",
                    fit: BoxFit.cover,
                  ),
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottomPaddingForCard * (1.2 - 0.25 * t),
                  left: 16,
                  right: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                    minHeight: 80,
                    maxHeight: 180,
                  ),
                  child: const IntrinsicHeight(child: SizedBox.shrink()),
                ),
              ),
            ),
          ),

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
                    tutorialKeys: tutorialKeys, // ✅ Pasar aquí
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
  }
}
