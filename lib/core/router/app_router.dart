import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/features/splash/splash_screen.dart';
import 'package:migozz_app/core/utils/pages/deleted_policy.dart';
import 'package:migozz_app/core/utils/pages/support/support_screen.dart';
import 'package:migozz_app/core/utils/pages/terms_and_policy_screen.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/login/login_entry.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_entry.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/profile/components/main_navigation.dart';
import 'package:migozz_app/features/profile/presentation/edit/web/edit_profile_page.dart'
    show EditProfilePage;
import 'package:migozz_app/features/profile/presentation/edit/web/web_visual_edit_page.dart'
    show WebVisualEditPage;
import 'package:migozz_app/features/profile/presentation/profile/modules/complete_profile.dart';
import 'package:migozz_app/features/chat/presentation/register/ia_chat_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/list/chats_list_screen.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile_entry.dart';
import 'package:migozz_app/features/profile/presentation/stats/web/profile_stats.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_search_screen.dart'
    as web_profile;
import 'package:migozz_app/features/profile/presentation/followers/followers_list_screen.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/search/web/presentation/search_screen.dart'
    as web_search;
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/notifications/presentation/notifications_list_screen.dart';
import 'package:migozz_app/features/notifications/presentation/web/web_notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/profile/presentation/public_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/followers/web/web_followers_screen.dart';
import 'package:migozz_app/features/chat/presentation/user/list/web_chat_screen.dart';

Widget localizedBuilder(BuildContext context, Widget Function() screenBuilder) {
  final easy = EasyLocalization.of(context);

  if (easy == null) return screenBuilder();

  final controller = easy.delegate.localizationController;

  if (controller == null) {
    return const SplashScreen();
  }

  return screenBuilder();
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _hasShownBannedDialog = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔒 Esperar a que la autenticación esté completamente resuelta
      final authCubit = context.read<AuthCubit>();
      final authStatus = authCubit.state.status;

      // Solo redirigir si ya se resolvió el estado (no está checking)
      if (authStatus == AuthStatus.authenticated) {
        if (mounted) context.go('/profile');
      } else if (authStatus == AuthStatus.notAuthenticated) {
        if (mounted) context.go('/onboarding');
      } else if (authStatus == AuthStatus.userBanned) {
        _showBannedDialog();
      }
      // Si está checking, se mantiene el splash hasta que cambie
    });
  }

  void _showBannedDialog() {
    if (_hasShownBannedDialog || !mounted) return;
    _hasShownBannedDialog = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'tutorial.accountStatus.bannedLogin.title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'tutorial.accountStatus.bannedLogin.message'.tr(),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text('tutorial.accountStatus.button'.tr()),
          ),
        ],
      ),
    ).then((_) {
      // Se ejecuta cuando el diálogo se cierra (botón o tocar fuera)
      // ignore: use_build_context_synchronously
      context.read<AuthCubit>().clearBannedState();
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Escuchar cambios de autenticación para redirigir cuando esté listo
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Una vez que deja de estar checking, redirigir según corresponda
        if (state.status == AuthStatus.authenticated && mounted) {
          debugPrint(
            '🔐 [AppGate] Auth resolved: authenticated → going to /profile',
          );
          context.go('/profile');
        } else if (state.status == AuthStatus.notAuthenticated && mounted) {
          debugPrint(
            '🔐 [AppGate] Auth resolved: notAuthenticated → going to /onboarding',
          );
          context.go('/onboarding');
        } else if (state.status == AuthStatus.userBanned && mounted) {
          debugPrint('🚫 [AppGate] Auth resolved: userBanned → showing popup');
          _showBannedDialog();
        }
      },
      child: const SplashScreen(),
    );
  }
}

GoRouter createRouter(GoRouterNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppGate()),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            localizedBuilder(context, () => const OnboardingEntry()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            localizedBuilder(context, () => const LoginEntry()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) =>
            localizedBuilder(context, () => const RegisterScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainNavigation(initialIndex: 0),
      ),
      GoRoute(
        path: '/profile-view',
        builder: (context, state) {
          final user = state.extra as UserDTO?;
          if (user == null) {
            return ProfileEntry(tutorialKeys: TutorialKeys());
          }
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return web_profile.ProfileSearchScreen(user: user);
          }
          return MainNavigation(initialIndex: 0, targetUser: user);
        },
      ),

      GoRoute(
        path: '/search',
        builder: (context, state) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return const web_search.SearchScreen();
          }
          return const MainNavigation(initialIndex: 1);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/visual-edit',
        builder: (context, state) => const WebVisualEditPage(),
      ),
      GoRoute(
        path: '/policy-deleted',
        name: 'policyDeleted',
        builder: (context, state) => const DataDeletionScreen(),
      ),
      GoRoute(
        path: '/terms-privacy',
        name: 'terms&Privacy',
        builder: (context, state) =>
            localizedBuilder(context, () => const TermsPrivacyScreen()),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) =>
            localizedBuilder(context, () => const SupportScreen()),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfile(),
      ),
      GoRoute(
        path: '/ia-chat',
        builder: (context, state) {
          final email =
              state.extra as String? ??
              context.read<RegisterCubit>().state.email;

          if (email != null) {
            context.read<RegisterCubit>().setEmail(email);
          }

          return const IaChatScreen();
        },
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) =>
            WebProfileStats(user: context.read<AuthCubit>().state.userProfile!),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return const WebNotificationsScreen();
          }
          return const NotificationsListScreen();
        },
      ),
      GoRoute(
        path: '/followers/:userId',
        name: 'followers',
        builder: (context, state) {
          final userId = Uri.decodeComponent(
            state.pathParameters['userId'] ?? '',
          );
          final username = Uri.decodeComponent(
            state.uri.queryParameters['username'] ?? '',
          );
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;

          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return WebFollowersScreen(
              userId: userId,
              username: username,
              initialTab: tab,
            );
          }

          return FollowersListScreen(
            userId: userId,
            username: username,
            initialTab: tab,
          );
        },
      ),
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) {
          final authState = context.read<AuthCubit>().state;
          final currentUser = authState.userProfile;

          if (currentUser == null) {
            return const SplashScreen();
          }

          final currentUserEmail = currentUser.email;
          final currentUsername = (currentUser.username).replaceFirst('@', '');

          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return WebChatScreen(
              username: currentUsername,
              currentUserId: currentUserEmail,
            );
          }

          return ChatsListScreen(
            username: currentUsername,
            currentUserId: currentUserEmail,
          );
        },
      ),
      GoRoute(
        path: '/chat/:userId',
        name: 'chat',
        builder: (context, state) {
          final otherUserId = state.pathParameters['userId'] ?? '';
          final authState = context.read<AuthCubit>().state;
          final currentUserId = authState.userProfile?.email ?? '';

          // Load other user's data
          return FutureBuilder<Map<String, dynamic>?>(
            future: _loadUserDataByEmail(otherUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final userData = snapshot.data;
              final otherUserName =
                  userData?['displayName'] ?? userData?['username'] ?? 'User';
              final otherUserAvatar = userData?['avatarUrl'] as String?;

              return UserChatScreen(
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserAvatar: otherUserAvatar,
                currentUserId: currentUserId,
              );
            },
          );
        },
      ),

      // 🆕 Ruta /u/:username — formato de links compartidos (migozz.com/u/natch)
      GoRoute(
        path: '/u/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'];
          if (username == null || username.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Usuario no encontrado')),
            );
          }
          return FutureBuilder<UserDTO?>(
            future: _loadUserByUsername(username),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Usuario @$username no encontrado',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Ir al inicio'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final user = snapshot.data!;
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth >= 900) {
                return web_profile.ProfileSearchScreen(user: user);
              }
              return MainNavigation(initialIndex: 0, targetUser: user);
            },
          );
        },
      ),

      // 🆕 Nueva ruta para manejar /:username (App Links y Web)
      // ⚠️ IMPORTANTE: Esta ruta debe ir AL FINAL para no interceptar otras rutas
      GoRoute(
        path: '/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'];

          if (username == null || username.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Usuario no encontrado')),
            );
          }

          // Cargar el perfil del usuario usando el username
          return FutureBuilder<UserDTO?>(
            future: _loadUserByUsername(username),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Usuario @$username no encontrado',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Ir al inicio'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final user = snapshot.data!;
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth >= 900) {
                return web_profile.ProfileSearchScreen(user: user);
              }
              return PublicProfileScreen(user: user);
            },
          );
        },
      ),
    ],
    redirect: (context, state) {
      final localization = EasyLocalization.of(context);
      if (localization == null ||
          !localization.supportedLocales.contains(localization.locale)) {
        return null;
      }

      final status = goRouterNotifier.authStatus;

      String normalize(String loc) {
        final noQuery = loc.split('?').first;
        if (noQuery != '/' && noQuery.endsWith('/')) {
          return noQuery.substring(0, noQuery.length - 1);
        }
        return noQuery;
      }

      final goingTo = normalize(state.uri.toString());
      debugPrint('REDIRECT -> status: $status, goingTo: $goingTo');

      final authCubit = context.read<AuthCubit>();
      final registerCubit = context.read<RegisterCubit>();
      final authState = authCubit.state;
      final registerState = registerCubit.state;

      const publicRoutes = {
        '/login',
        '/register',
        '/onboarding',
        '/ia-chat',
        '/otp',
        '/terms-privacy',
        '/policy-deleted',
        '/support',
        '/complete-profile', // TEMPORARY: Allow access for testing
      };

      bool routeMatches(String loc, String route) {
        if (loc == route) return true;
        if (loc.startsWith('$route/')) return true;
        return false;
      }

      final isPublic = publicRoutes.any((r) => routeMatches(goingTo, r));

      // ✅ Permitir acceso público a perfiles /u/:username
      final pathSegments = Uri.parse(goingTo).pathSegments;
      if (pathSegments.length == 2 && pathSegments.first == 'u') {
        return null; // Es /u/:username — permitir acceso público
      }

      // ✅ Permitir acceso público a perfiles /:username
      // Lógica: Si la ruta tiene 1 segmento y NO es una ruta reservada del sistema, es un perfil.
      if (pathSegments.length == 1) {
        final rootSegment = pathSegments.first;
        final reservedRoots = {
          'onboarding',
          'login',
          'register',
          'profile',
          'profile-view',
          'search',
          'edit-profile',
          'visual-edit',
          'policy-deleted',
          'terms-privacy',
          'support',
          'complete-profile',
          'ia-chat',
          'stats',
          'notifications',
          'followers',
          'chats',
          'chat',
          'splash', // por si acaso
        };

        if (!reservedRoots.contains(rootSegment)) {
          return null; // Es un perfil de usuario (o 404), permitir acceso
        }
      }

      // ✅ Permitir la ruta raíz para que se maneje su propio redirect
      if (goingTo == '/') return null;

      // 🆕 Mientras se está verificando la autenticación, mantener en splash
      if (status == AuthStatus.checking) {
        // Si intenta ir a splash, permitir
        if (goingTo == '/splash' || goingTo == '/') return null;
        // Si intenta ir a cualquier otro lado, quedarse en splash (no redirigir aún)
        return null;
      }

      // 🚫 Usuario baneado - redirigir a splash para mostrar popup
      if (status == AuthStatus.userBanned) {
        debugPrint('🚫 [Router] Usuario baneado - redirigiendo a / para popup');
        return '/';
      }

      // 1) NO autenticado
      if (status == AuthStatus.notAuthenticated) {
        final isInRegisterFlow =
            registerState.regProgress != RegisterStatusProgress.emty &&
            registerState.regProgress != RegisterStatusProgress.doneChat;

        if (isInRegisterFlow) {
          if (goingTo != '/ia-chat') return '/ia-chat';
          return null;
        }

        if (isPublic) return null;

        return '/login';
      }

      // 2) Autenticado
      if (status == AuthStatus.authenticated) {
        final userProfile = authState.userProfile;
        final hasActiveRegistration =
            registerState.regProgress != RegisterStatusProgress.emty &&
            registerState.regProgress != RegisterStatusProgress.doneChat;

        if (hasActiveRegistration) {
          if (goingTo != '/ia-chat') return '/ia-chat';
          return null;
        }

        // ✅ Si el perfil está incompleto, pero ya vió el diálogo en esta sesión, permitir navegación
        if (userProfile == null || !userProfile.complete) {
          if (authState.hasSeenCompleteProfileDialog) {
            // El usuario ya vio el diálogo, permitir que use la app normalmente
            debugPrint(
              '✅ [Router] Usuario ya vio diálogo de completar perfil - permitiendo navegación normal',
            );
            return null;
          }

          if (goingTo != '/complete-profile' && goingTo != '/ia-chat') {
            debugPrint(
              '🔄 [Router] Perfil incompleto - redirigiendo a /complete-profile',
            );
            return '/complete-profile';
          }
          return null;
        }

        // ✅ Redirect to profile if authenticated user tries to access onboarding or login
        if (goingTo == '/onboarding' || goingTo == '/login') {
          return '/profile';
        }

        const allowedWhenComplete = {
          '/profile',
          '/profile-view',
          '/edit-profile',
          '/visual-edit',
          '/stats',
          '/search',
          '/notifications',
          '/chat',
          '/chats',
          '/followers',
          '/u',
        };

        final allowed =
            allowedWhenComplete.any((r) => routeMatches(goingTo, r)) ||
            isPublic;

        if (!allowed) {
          return '/profile';
        }
      }

      return null;
    },
  );
}

/// Función helper para cargar usuario por username
Future<UserDTO?> _loadUserByUsername(String username) async {
  try {
    final cleanUsername = username.toLowerCase().replaceFirst('@', '');

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final userData = querySnapshot.docs.first.data();

    // Usar UserDTO.fromMap que ya maneja todos los campos defensivamente
    return UserDTO.fromMap(userData);
  } catch (e) {
    debugPrint('Error loading user by username: $e');
    return null;
  }
}

/// Función helper para cargar datos de usuario por email
Future<Map<String, dynamic>?> _loadUserDataByEmail(String email) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return querySnapshot.docs.first.data();
  } catch (e) {
    debugPrint('Error loading user by email: $e');
    return null;
  }
}
