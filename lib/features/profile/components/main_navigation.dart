import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/presentation/edit/mobile/edit_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile_entry.dart';
import 'package:migozz_app/features/profile/presentation/stats/mobile/profile_stats.dart';
import 'package:migozz_app/features/search/mobile/presentation/search_screen.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class MainNavigation extends StatefulWidget {
  final TutorialKeys? tutorialKeys;
  final int initialIndex;

  const MainNavigation({super.key, this.tutorialKeys, this.initialIndex = 0});

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

    final screens = [
      const ProfileEntry(), // 0: Home
      const SearchScreen(), // 1: Search
      const ProfileStatsScreen(), // 2: Stats
      const EditProfileScreen(), // 3: Settings
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: GradientBottomNav(
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
        onCenterTap: _onCenterTap,
        onProfileUpdated: _onProfileUpdated,
        tutorialKeys: widget.tutorialKeys,
      ),
    );
  }
}
