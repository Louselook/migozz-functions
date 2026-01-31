import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class SideMenu extends StatelessWidget {
  final TutorialKeys? tutorialKeys;
  final VoidCallback? onChatTap;
  final bool isChatOpen;
  final int unreadCount;

  const SideMenu({
    super.key,
    this.tutorialKeys,
    this.onChatTap,
    this.isChatOpen = false,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    // Ruta actual
    final currentRoute = GoRouterState.of(context).uri.toString();

    // Responsive configs
    final menuWidth = isSmallScreen
        ? 90.0
        : isMediumScreen
        ? 100.0
        : 150.0;

    final borderRadius = isSmallScreen ? 15.0 : 20.0;

    final createButtonSize = isSmallScreen
        ? 56.0
        : isMediumScreen
        ? 60.0
        : 64.0;

    final createIconSize = isSmallScreen
        ? 28.0
        : isMediumScreen
        ? 30.0
        : 32.0;

    final createFontSize = isSmallScreen
        ? 10.0
        : isMediumScreen
        ? 11.0
        : 12.0;

    return Container(
      width: menuWidth,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        border: Border(
          right: BorderSide(
            color: const Color.fromARGB(
              209,
              255,
              255,
              255,
            ).withValues(alpha: 0.6),
            width: isSmallScreen ? 1.5 : 2.0,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 15.0 : 20.0),

          // Menú items
          Expanded(
            child: Column(
              children: [
                // _MenuItem(
                //   icon: Icons.home,
                //   label: 'Home',
                //   isSelected: currentRoute == '/home' || currentRoute == '/',
                //   isSmallScreen: isSmallScreen,
                //   isMediumScreen: isMediumScreen,
                //   onTap: () {
                //     context.go('/home');
                //   },
                // ),
                _MenuItem(
                  icon: Icons.search,
                  label: 'Search',
                  isSelected: currentRoute == '/search',
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  onTap: () {
                    context.go('/search');
                  },
                ),
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected:
                      currentRoute == '/profile' ||
                      currentRoute == '/' ||
                      currentRoute.contains('profile'),
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  tutorialKey: tutorialKeys?.profileScreenKey,
                  onTap: () {
                    context.go('/profile');
                  },
                ),
                _MenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  isSelected: isChatOpen,
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  badgeCount: unreadCount,
                  onTap: () {
                    if (onChatTap != null) {
                      onChatTap!();
                    } else {
                      context.go('/chats');
                    }
                  },
                ),
                // _MenuItem(
                //   icon: Icons.link,
                //   label: 'Feed',
                //   isSelected: currentRoute.contains('feed'),
                //   isSmallScreen: isSmallScreen,
                //   isMediumScreen: isMediumScreen,
                //   onTap: () {
                //     context.go('/feed');
                //   },
                // ),
                _MenuItem(
                  icon: Icons.bar_chart,
                  label: 'My Stats',
                  isSelected: currentRoute.contains('stats'),
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  tutorialKey: tutorialKeys?.statScreenKey,
                  onTap: () {
                    context.go('/stats');
                  },
                ),
                _MenuItem(
                  icon: Icons.settings,
                  label: 'Configuration',
                  isSelected: currentRoute.contains('edit-profile'),
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  tutorialKey: tutorialKeys?.editScreenKey,
                  onTap: () {
                    context.go('/edit-profile');
                  },
                ),
              ],
            ),
          ),

          // Botón Create
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 20.0 : 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: createButtonSize,
                  height: createButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF0050), Color(0xFFFF6B9D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0050).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.go('/create');
                      },
                      borderRadius: BorderRadius.circular(createButtonSize / 2),
                      child: Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: createIconSize,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: createFontSize,
                    fontWeight: FontWeight.w500,
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final VoidCallback onTap;
  final GlobalKey? tutorialKey;
  final int badgeCount;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.onTap,
    this.tutorialKey,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen
        ? 24.0
        : isMediumScreen
        ? 26.0
        : 28.0;

    final fontSize = isSmallScreen
        ? 9.0
        : isMediumScreen
        ? 10.0
        : 11.0;

    final verticalPadding = isSmallScreen
        ? 12.0
        : isMediumScreen
        ? 14.0
        : 16.0;

    final horizontalPadding = isSmallScreen
        ? 8.0
        : isMediumScreen
        ? 10.0
        : 12.0;

    final spacing = isSmallScreen ? 4.0 : 6.0;

    return InkWell(
      key: tutorialKey,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFF0050) : Colors.white70,
                  size: iconSize,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF0050),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacing),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF0050) : Colors.white70,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
