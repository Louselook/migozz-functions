import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/chat/presentation/user/list/chats_list_screen.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/mobile/edit_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile_entry.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_search_screen.dart';
import 'package:migozz_app/features/profile/presentation/stats/mobile/profile_stats.dart';
import 'package:migozz_app/features/search/mobile/presentation/search_screen.dart';
// import 'package:migozz_app/features/tutorial/profile_tutorial_helper.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'package:migozz_app/features/chat/presentation/web/floating_chat_widget.dart';

class MainNavigation extends StatefulWidget {
  final TutorialKeys? tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;
  final int initialIndex;
  final UserDTO? targetUser; // ✅ Usuario a mostrar (si es perfil de otro)

  const MainNavigation({
    super.key,
    this.tutorialKeys,
    this.profileTutorialKeys,
    this.initialIndex = 0,
    this.targetUser, // ✅ Opcional
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  bool _tutorialInFlight = false;
  late final VoidCallback _replayListener;
  int _lastReplayToken = 0;

  late final TutorialKeys _tutorialKeys = widget.tutorialKeys ?? TutorialKeys();
  late final ProfileTutorialKeys _profileTutorialKeys =
      widget.profileTutorialKeys ?? ProfileTutorialKeys();
  final GlobalKey<EditProfileScreenState> editProfileKey =
      GlobalKey<EditProfileScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    debugPrint('🚀 [MainNavigation] Inicializado con index: $_currentIndex');

    _replayListener = _handleReplayRequest;
    ProfileTutorialReplayBus.listenable.addListener(_replayListener);

    // Inicializar FollowerCubit con el ID del usuario actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFollowerCubit();
      _maybeTriggerProfileTutorial();
    });
  }

  @override
  void dispose() {
    ProfileTutorialReplayBus.listenable.removeListener(_replayListener);
    super.dispose();
  }

  void _handleReplayRequest() {
    final token = ProfileTutorialReplayBus.listenable.value;
    if (token == _lastReplayToken) return;
    _lastReplayToken = token;

    if (!mounted) return;

    // Ir al tab del perfil y reproducir el tutorial cuando la UI esté lista.
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      await ProfileTutorialHelper.replayTutorial(context, _profileTutorialKeys);
    });
  }

  Future<void> _maybeTriggerProfileTutorial() async {
    // No mostrar tutorial si es navegación del perfil de otro usuario.
    if (widget.targetUser != null) return;
    if (_currentIndex != 0) return;
    if (_tutorialInFlight) return;

    _tutorialInFlight = true;
    try {
      await ProfileTutorialHelper.triggerProfileTutorial(
        context,
        _profileTutorialKeys,
      );
    } finally {
      _tutorialInFlight = false;
    }
  }

  void _initializeFollowerCubit() {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState.firebaseUser?.uid;
    if (currentUserId != null) {
      final followerCubit = context.read<FollowerCubit>();
      followerCubit.initialize(currentUserId);
      followerCubit.loadCounts(currentUserId);
      debugPrint(
        '✅ [MainNavigation] FollowerCubit inicializado para UID: $currentUserId',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Si entramos a dependencias con el perfil visible, intentar mostrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeTriggerProfileTutorial();
    });
  }

  void _onItemSelected(int index) {
    // Si tenemos targetUser (estamos en la navegación del perfil de otro usuario)
    if (widget.targetUser != null) {
      // Si estamos viendo el perfil del otro (index 0) y presionamos home o lupa, volver atrás
      if (_currentIndex == 0 && (index == 0 || index == 1)) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Si estamos en stats/config y presionamos home, volver atrás (a nuestra navegación principal)
      if (_currentIndex != 0 && index == 0) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Si estamos en stats/config y presionamos lupa, ir al perfil del otro usuario (índice 0)
      if (_currentIndex != 0 && index == 1) {
        _performNavigation(0); // Ir al perfil del otro usuario
        return;
      }
    }

    if (_currentIndex == index) {
      debugPrint('⚠️ [MainNavigation] Ya estás en el index $index, ignorando');
      return;
    }

    if (_currentIndex == 3 && index != 3) {
      // Si estamos saliendo de "Editar Perfil", verificar cambios
      _checkAndNavigate(index);
      return;
    }

    _performNavigation(index);
  }

  Future<void> _checkAndNavigate(int index) async {
    final state = editProfileKey.currentState;
    if (state != null) {
      final canLeave = await state.confirmDiscardOrSave();
      if (!canLeave) return;
    }
    _performNavigation(index);
  }

  void _performNavigation(int index) {
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchKey.currentState?.checkAndMaybeOpenEditInterests();
      });
    }

    debugPrint('🔄 [MainNavigation] Navegando de $_currentIndex → $index');
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeTriggerProfileTutorial();
      });
    }
  }

  Future<void> _onCenterTap() async {
    debugPrint('🎯 [MainNavigation] Botón central presionado - ir a chats');

    // Intentamos obtener el usuario actual desde el AuthCubit
    final authState = context.read<AuthCubit>().state;
    final currentUser = authState.userProfile;

    if (currentUser == null) {
      AlertGeneral.show(
        context,
        4,
        message: 'No se ha encontrado usuario activo',
      );
      return;
    }

    final currentUserEmail = currentUser.email;
    final currentUsername = (currentUser.username).replaceFirst('@', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatsListScreen(
          username: currentUsername,
          currentUserId: currentUserEmail,
        ),
      ),
    );
  }

  void _onProfileUpdated() {
    debugPrint('🔄 [MainNavigation] Perfil actualizado');
    context.read<AuthCubit>().refreshUserProfile();
  }

  final GlobalKey<SearchScreenState> searchKey = GlobalKey<SearchScreenState>();

  @override
  Widget build(BuildContext context) {
    final isViewingOtherProfile = widget.targetUser != null;

    // Check if user is authenticated
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated =
        authState.status == AuthStatus.authenticated &&
        authState.userProfile != null;

    // When not authenticated and viewing another profile, only show that profile
    if (isViewingOtherProfile && !isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: ProfileSearchScreen(
          user: widget.targetUser!,
          tutorialKeys: _tutorialKeys,
        ),
      );
    }

    final screens = [
      isViewingOtherProfile
          ? ProfileSearchScreen(
              user: widget.targetUser!,
              tutorialKeys: _tutorialKeys,
            )
          : ProfileEntry(
              tutorialKeys: _tutorialKeys,
              profileTutorialKeys: _profileTutorialKeys,
            ),

      SearchScreen(key: searchKey, tutorialKeys: _tutorialKeys),

      ProfileStatsScreen(tutorialKeys: _tutorialKeys),
      EditProfileScreen(
        key: editProfileKey,
        tutorialKeys: _tutorialKeys,
        profileTutorialKeys: _profileTutorialKeys,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          if (PlatformUtils.isWeb) const FloatingChatWidget(),
        ],
      ),
      bottomNavigationBar: PlatformUtils.isWeb
          ? null
          : GradientBottomNav(
              currentIndex: _currentIndex,
              onItemSelected: _onItemSelected,
              onCenterTap: _onCenterTap,
              onProfileUpdated: _onProfileUpdated,
              tutorialKeys: _tutorialKeys,
              profileTutorialKeys: _profileTutorialKeys,
            ),
    );
  }
}
