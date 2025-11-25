import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/presentation/edit/mobile/edit_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile_entry.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_search_screen.dart';
import 'package:migozz_app/features/profile/presentation/stats/mobile/profile_stats.dart';
import 'package:migozz_app/features/search/mobile/presentation/search_screen.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class MainNavigation extends StatefulWidget {
  final TutorialKeys? tutorialKeys;
  final int initialIndex;
  final UserDTO? targetUser; // ✅ Usuario a mostrar (si es perfil de otro)

  const MainNavigation({
    super.key,
    this.tutorialKeys,
    this.initialIndex = 0,
    this.targetUser, // ✅ Opcional
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    debugPrint('🚀 [MainNavigation] Inicializado con index: $_currentIndex');
    if (widget.targetUser != null) {
      debugPrint(
        '👤 [MainNavigation] Mostrando perfil de: ${widget.targetUser!.username}',
      );
    }
  }

  void _onItemSelected(int index) {
    if (_currentIndex == index) {
      debugPrint('⚠️ [MainNavigation] Ya estás en el index $index, ignorando');
      return;
    }

    debugPrint('🔄 [MainNavigation] Navegando de $_currentIndex → $index');
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onCenterTap() async {
    debugPrint('🎯 [MainNavigation] Botón central presionado');

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      debugPrint('👋 [MainNavigation] Usuario cerrando sesión');
      await FirebaseAuth.instance.signOut();
    }
  }

  void _onProfileUpdated() {
    debugPrint('🔄 [MainNavigation] Perfil actualizado');
    context.read<AuthCubit>().refreshUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [MainNavigation] Building con index: $_currentIndex');

    // ✅ Si hay targetUser, mostrar su perfil en lugar del propio
    final isViewingOtherProfile = widget.targetUser != null;

    final screens = [
      // 0: Home - ProfileEntry propio o perfil de otro usuario
      isViewingOtherProfile
          ? ProfileSearchScreen(user: widget.targetUser!)
          : const ProfileEntry(),

      // 1: Search
      const SearchScreen(),

      // 2: Stats - Solo para perfil propio
      const ProfileStatsScreen(),

      // 3: Settings - Solo para perfil propio
      const EditProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),

      // ✅ Solo mostrar bottom nav si es perfil propio
      bottomNavigationBar: isViewingOtherProfile
          ? null // No mostrar nav al ver perfil de otro
          : GradientBottomNav(
              currentIndex: _currentIndex,
              onItemSelected: _onItemSelected,
              onCenterTap: _onCenterTap,
              onProfileUpdated: _onProfileUpdated,
              tutorialKeys: widget.tutorialKeys,
            ),
    );
  }
}
