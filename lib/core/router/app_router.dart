import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/utils/pages/deleted_policy.dart';
import 'package:migozz_app/core/utils/pages/support/support_screen.dart';
import 'package:migozz_app/core/utils/pages/terms_and_policy_screen.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/login/login_entry.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_entry.dart';
// import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/profile/components/main_navigation.dart';
import 'package:migozz_app/features/profile/presentation/edit/web/edit_profile_page.dart'
    show EditProfilePage;
import 'package:migozz_app/features/profile/presentation/profile/modules/complete_profile.dart';
import 'package:migozz_app/features/chat/presentation/register/ia_chat_screen.dart';
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

Widget localizedBuilder(BuildContext context, Widget Function() screenBuilder) {
  final easy = EasyLocalization.of(context);

  if (easy == null) return screenBuilder();

  final controller = easy.delegate.localizationController;

  if (controller == null) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return screenBuilder();
}

GoRouter createRouter(GoRouterNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final status = goRouterNotifier.authStatus;

          // If we are still checking, do not redirect.
          if (status == AuthStatus.checking) return null;

          // If you are logged in, go to profile
          if (status == AuthStatus.authenticated) {
            final authCubit = context.read<AuthCubit>();
            final userProfile = authCubit.state.userProfile;

            if (userProfile != null && userProfile.complete) {
              return '/profile';
            }
            return '/complete-profile';
          }

          // If you are not authenticated, go to onboarding
          return '/onboarding';
        },
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
