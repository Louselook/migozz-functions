import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';

class GradientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onCenterTap;
  final VoidCallback? onProfileUpdated;
  final TutorialKeys? tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;

  const GradientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onCenterTap,
    this.onProfileUpdated,
    this.tutorialKeys,
    this.profileTutorialKeys,
  });

  static const double _barHeight = 64;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                height: _barHeight + bottomInset,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_radius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.55),
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: bottomInset,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        tutorialKey: profileTutorialKeys?.homeNavKey ?? tutorialKeys?.profileScreenKey,
                        icon: Icons.home_outlined,
                        selected: currentIndex == 0,
                        onTap: () => onItemSelected(0), // ✅ Solo callback
                      ),
                      _NavItem(
                        tutorialKey: profileTutorialKeys?.searchNavKey ?? tutorialKeys?.searchScreenKey,
                        icon: Icons.search,
                        selected: currentIndex == 1,
                        onTap: () => onItemSelected(1), // ✅ Solo callback
                      ),
       
                      _NavItem(
                        tutorialKey: profileTutorialKeys?.statsNavKey ?? tutorialKeys?.statScreenKey,
                        icon: Icons.bar_chart_rounded,
                        selected: currentIndex == 2,
                        onTap: () => onItemSelected(2), // ✅ Solo callback
                      ),
                      _NavItem(
                        tutorialKey: profileTutorialKeys?.settingsNavKey ?? tutorialKeys?.editScreenKey,
                        icon: Icons.settings_outlined,
                        selected: currentIndex == 3,
                        onTap: () => onItemSelected(3), // ✅ Solo callback
                      ),

                      _NavItem(
                        tutorialKey: null,
                        icon: Icons.wallet,
                        selected: currentIndex == 4,
                        onTap: () => onItemSelected(4), // ✅ Solo callback
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left:
                MediaQuery.of(context).size.width / 2 -
                28, // Center - half the size of the button
            child: SizedBox(
              key: profileTutorialKeys?.messagesNavKey,
              width: 56, // Fixed button size
              height: 56, // Fixed button size
              child: _CenterActionButton(onTap: onCenterTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final GlobalKey? tutorialKey;

  const _NavItem({
    this.tutorialKey,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.7);
    return Expanded(
      child: InkResponse(
        key: tutorialKey,
        onTap: onTap,
        radius: 0,
        child: SizedBox(
          height: double.infinity,
          child: Icon(icon, color: color, size: 36),
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB86BFF), Color(0xFFFF5F9A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset(
          AssetsConstants.inboxIcon,
          width: 23,
          height: 23,
          color: Colors.white,
        ),
      ),
    );
  }
}
