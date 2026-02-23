import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/web_add_custom_link_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

class SideMenu extends StatelessWidget {
  final TutorialKeys? tutorialKeys;
  final VoidCallback? onChatTap;
  final bool isChatOpen;
  final int unreadCount;

  /// If null, auto-detects from [AuthCubit].
  final bool? isAuthenticated;

  const SideMenu({
    super.key,
    this.tutorialKeys,
    this.onChatTap,
    this.isChatOpen = false,
    this.unreadCount = 0,
    this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect auth state when not explicitly provided
    final isAuth =
        isAuthenticated ?? context.watch<AuthCubit>().state.isAuthenticated;

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    // Ruta actual
    final currentRoute = GoRouterState.of(context).uri.toString();

    // Responsive configs
    final menuWidth = isSmallScreen
        ? 60.0
        : isMediumScreen
        ? 70.0
        : 80.0;

    final createButtonSize = isSmallScreen
        ? 46.0
        : isMediumScreen
        ? 50.0
        : 54.0;

    final createIconSize = isSmallScreen
        ? 24.0
        : isMediumScreen
        ? 26.0
        : 28.0;

    final createFontSize = isSmallScreen
        ? 9.0
        : isMediumScreen
        ? 10.0
        : 11.0;

    return Container(
      width: menuWidth,
      decoration: const BoxDecoration(color: Color(0xFF1B1B1B)),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 10.0 : 14.0),

          // Menú items
          Expanded(
            child: isAuth
                ? Column(
                    children: [
                      _MenuItem(
                        icon: Icons.search,
                        label: 'web.menu.search'.tr(),
                        isSelected: currentRoute == '/search',
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        onTap: () {
                          context.go('/search');
                        },
                      ),
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: 'web.menu.profile'.tr(),
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
                        label: 'web.menu.chat'.tr(),
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
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'web.menu.notifications'.tr(),
                        isSelected: currentRoute.contains('notifications'),
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        onTap: () {
                          context.go('/notifications');
                        },
                      ),
                      // Followers removed — visible in Stats page
                      _MenuItem(
                        icon: Icons.bar_chart,
                        label: 'web.menu.stats'.tr(),
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
                        label: 'web.menu.configuration'.tr(),
                        isSelected: currentRoute.contains('edit-profile'),
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        tutorialKey: tutorialKeys?.editScreenKey,
                        onTap: () {
                          context.go('/edit-profile');
                        },
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      _MenuItem(
                        icon: Icons.login,
                        label: 'web.menu.login'.tr(),
                        isSelected: false,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        onTap: () {
                          context.go('/login');
                        },
                      ),
                      _MenuItem(
                        icon: Icons.person_add_outlined,
                        label: 'web.menu.signup'.tr(),
                        isSelected: false,
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        onTap: () {
                          context.go('/register');
                        },
                      ),
                    ],
                  ),
          ),
          if (kIsWeb && isAuth)
            _MenuItem(
              icon: Icons.logout,
              label: 'web.menu.logout'.tr(),
              isSelected: false,
              isSmallScreen: isSmallScreen,
              isMediumScreen: isMediumScreen,
              onTap: () {
                context.read<AuthCubit>().logout();
              },
            ),

          // Botón Create — solo para usuarios autenticados
          if (isAuth)
            Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 14.0 : 20.0),
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
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: WebAddCustomLinkModal(
                                onComplete: () {
                                  Navigator.of(ctx).pop();
                                },
                                onBack: () {
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          createButtonSize / 2,
                        ),
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
                    "web.menu.create".tr(),
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
        ? 20.0
        : isMediumScreen
        ? 22.0
        : 24.0;

    final fontSize = isSmallScreen
        ? 8.0
        : isMediumScreen
        ? 9.0
        : 10.0;

    final verticalPadding = isSmallScreen
        ? 10.0
        : isMediumScreen
        ? 12.0
        : 14.0;

    final horizontalPadding = isSmallScreen
        ? 7.0
        : isMediumScreen
        ? 9.0
        : 11.0;

    final spacing = isSmallScreen ? 3.5 : 5.0;

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
