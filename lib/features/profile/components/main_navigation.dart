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
import 'package:migozz_app/features/tutorial/profile_tutorial_helper.dart';
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
  bool _tutorialScheduled = false;

  late final TutorialKeys _tutorialKeys = widget.tutorialKeys ?? TutorialKeys();

   @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    debugPrint('🚀 [MainNavigation] Inicializado con index: $_currentIndex');
  }

 @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_tutorialScheduled && widget.tutorialKeys != null && _currentIndex == 0) {
      _tutorialScheduled = true;

      // Espera a que el build ACTUAL termine
      WidgetsBinding.instance.addPostFrameCallback((_) {

        // Espera otro frame más para asegurar que BottomNav existe
        Future.delayed(const Duration(milliseconds: 200), () {

          if (!mounted) return;

          triggerProfileTutorial(context, widget.tutorialKeys!);
        });
      });
    }
    if (!_tutorialScheduled && widget.tutorialKeys != null) {
      _tutorialScheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 1. Asegurar el tab correcto
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // 2. Esperar un frame extra
        await Future.delayed(const Duration(milliseconds: 200));

        // 3. Ahora sí lanzar tutorial
        if (mounted) {
          triggerProfileTutorial(context, widget.tutorialKeys!);
        }
      });
    }
  }

  void _onItemSelected(int index) {
    if (_currentIndex == index) {
      debugPrint('⚠️ [MainNavigation] Ya estás en el index $index, ignorando');
      return;
    }
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchKey.currentState?.checkAndMaybeOpenEditInterests();
      });
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
  final GlobalKey<SearchScreenState> searchKey = GlobalKey<SearchScreenState>();

  @override
  Widget build(BuildContext context) {
    final isViewingOtherProfile = widget.targetUser != null;

    final screens = [
  isViewingOtherProfile
      ? ProfileSearchScreen(user: widget.targetUser!, tutorialKeys: _tutorialKeys)
      : ProfileEntry(tutorialKeys: _tutorialKeys),

      SearchScreen(key: searchKey, tutorialKeys: _tutorialKeys),

      ProfileStatsScreen(tutorialKeys: _tutorialKeys),
      EditProfileScreen(tutorialKeys: _tutorialKeys),
    ];  

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: isViewingOtherProfile
          ? null
          : GradientBottomNav(
              currentIndex: _currentIndex,
              onItemSelected: _onItemSelected,
              onCenterTap: _onCenterTap,
              onProfileUpdated: _onProfileUpdated,
              tutorialKeys: _tutorialKeys, // <- PASAR la MISMA instancia
            ),
    );
  }
}
