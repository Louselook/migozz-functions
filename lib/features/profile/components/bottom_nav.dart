import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/edit_profile.dart';
import 'package:migozz_app/features/profile/presentation/profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile_stats.dart';

class GradientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onCenterTap;

  const GradientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onCenterTap,
  });

  static const double _barHeight = 64;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: double.infinity, // Usa todo el ancho de la pantalla
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Barra con blur + gradiente
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double
                    .infinity, // Asegura que el container use todo el ancho
                height:
                    _barHeight +
                    bottomInset, // Incluye el espacio del bottom inset
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
                      const Color(0x00000000), // transparent
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: bottomInset, // Agrega padding inferior
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        selected: currentIndex == 0,
                         onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const ProfileScreen(),
                              ),
                           );
                        },
                      ),
                      _NavItem(
                        icon: Icons.link,
                        selected: currentIndex == 1,
                        onTap: () => onItemSelected(1),
                      ),
                      const Spacer(), // deja hueco para el botón central
                      _NavItem(
                        icon: Icons.bar_chart_rounded,
                        selected: currentIndex == 2,
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const ProfileStatsScreen(),
                              ),
                           );
                        },
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        selected: currentIndex == 3,
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const EditProfile(),
                              ),
                           );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botón central flotante (sobresale)
          Positioned(
            top: -22, // eleva el botón
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
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

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.7);
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          height: double.infinity,
          child: Icon(icon, color: color, size: 26),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      elevation: 12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
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
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
