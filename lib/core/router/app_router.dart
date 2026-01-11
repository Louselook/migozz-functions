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
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/search/web/presentation/search_screen.dart'
    as web_search;
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/notifications/presentation/notifications_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔒 Esperar UN frame garantiza que Easy ya cargó
      final authStatus = context.read<AuthCubit>().state.status;

      if (authStatus == AuthStatus.authenticated) {
        context.go('/profile');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

GoRouter createRouter(GoRouterNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AppGate(),
      ),

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

      // 🆕 Nueva ruta para manejar /u/:username (App Links y Web)
      GoRoute(
        path: '/u/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'];

          if (username == null || username.isEmpty) {
            // Si no hay username, redirigir a home
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
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Usuario @$username no encontrado',
                          style: const TextStyle(fontSize: 18),
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
        builder: (context, state) => const NotificationsListScreen(),
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
              final otherUserName = userData?['displayName'] ?? userData?['username'] ?? 'User';
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
      };

      bool routeMatches(String loc, String route) {
        if (loc == route) return true;
        if (loc.startsWith('$route/')) return true;
        return false;
      }

      final isPublic = publicRoutes.any((r) => routeMatches(goingTo, r));

      // ✅ Permitir acceso público a perfiles /u/:username
      if (goingTo.startsWith('/u/')) {
        return null; // Permitir acceso sin autenticación
      }

      // ✅ Permitir la ruta raíz para que se maneje su propio redirect
      if (goingTo == '/') return null;

      if (status == AuthStatus.checking) return null;

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

        if (userProfile == null || !userProfile.complete) {
          if (goingTo != '/complete-profile' && goingTo != '/ia-chat') {
            return '/complete-profile';
          }
          return null;
        }

        const allowedWhenComplete = {
          '/profile',
          '/profile-view',
          '/edit-profile',
          '/stats',
          '/search',
          '/notifications',
          '/chat',
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
