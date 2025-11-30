import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/utils/pages/deleted_policy.dart';
import 'package:migozz_app/core/utils/pages/support_screen.dart';
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

GoRouter createRouter(GoRouterNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: goRouterNotifier, // 🔑 clave
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingEntry(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginEntry()),
      // GoRoute(
      //   path: '/otp',
      //   builder: (context, state) {
      //     final data = state.extra as Map<String, dynamic>;
      //     return OtpScreen(email: data['email'], userOTP: data['userOTP']);
      //   },
      // ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
            // Si no hay usuario, redirigir al perfil propio
            return ProfileEntry(tutorialKeys: TutorialKeys(),);
          }

          // Decidir entre web y mobile según el ancho de pantalla
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth >= 900) {
            return web_profile.ProfileSearchScreen(user: user);
          }
          // return mobile_profile.ProfileSearchScreen(user: user);
          return MainNavigation(initialIndex: 0, targetUser: user);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          // Decide between web and mobile search screen using available MediaQuery size.
          final screenWidth = MediaQuery.of(context).size.width;
          // Breakpoint: use web search when wide enough (>= 900)
          if (screenWidth >= 900) {
            return const web_search.SearchScreen();
          }
          // return const mobile_search.SearchScreen();
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
        builder: (context, state) {
          final easy = EasyLocalization.of(context);
          // Fail-safe: si por alguna razón EasyLocalization no está presente, mostramos la pantalla igual.
          if (easy == null) return const TermsPrivacyScreen();

          // loadTranslations() carga (o reutiliza) las traducciones y devuelve un Future
          final loadFuture = easy.delegate.localizationController?.loadTranslations();

          return FutureBuilder<void>(
            future: loadFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                // Mientras carga, mostramos algo neutro (puede ser un skeleton del mismo layout)
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Ya cargó: ahora sí, construimos la pantalla real con las claves disponibles
              return const TermsPrivacyScreen();
            },
          );
        },
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) {
          final easy = EasyLocalization.of(context);
          // Fail-safe: si por alguna razón EasyLocalization no está presente, mostramos la pantalla igual.
          if (easy == null) return const SupportScreen();

          // loadTranslations() carga (o reutiliza) las traducciones y devuelve un Future
          final loadFuture = easy.delegate.localizationController?.loadTranslations();

          return FutureBuilder<void>(
            future: loadFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                // Mientras carga, mostramos algo neutro (puede ser un skeleton del mismo layout)
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Ya cargó: ahora sí, construimos la pantalla real con las claves disponibles
              return const SupportScreen();
            },
          );
        },
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfile(),
      ),
      GoRoute(
        path: '/ia-chat',
        builder: (context, state) {
          // Intentar tomar email desde extra
          final email = //"juanes.arenilla@gmail.com";
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
        // Si EasyLocalization aún no está listo, no redirijas todavía.
      if (localization == null || !localization.supportedLocales.contains(localization.locale)) {
        return null;
      }
      
      final status = goRouterNotifier.authStatus;
      // Normalizamos la ruta entrante (quitamos query y slash final)
      String normalize(String loc) {
        final noQuery = loc.split('?').first;
        if (noQuery != '/' && noQuery.endsWith('/')) {
          return noQuery.substring(0, noQuery.length - 1);
        }
        return noQuery;
      }

      final goingTo = normalize(state.uri.toString()); // usa location y no matchedLocation
      debugPrint('REDIRECT -> status: $status, goingTo: $goingTo');

      final authCubit = context.read<AuthCubit>();
      final registerCubit = context.read<RegisterCubit>();
      final authState = authCubit.state;
      final registerState = registerCubit.state;

      // Rutas públicas accesibles
      const publicRoutes = {
        '/login',
        '/register',
        '/onboarding',
        '/ia-chat',
        '/otp',
        '/terms-privacy',
        '/policy-deleted',
      };

      // Helper para comparar rutas (exacta o anidada)
      bool routeMatches(String loc, String route) {
        if (loc == route) return true;
        if (loc.startsWith('$route/')) return true; // p.ej. /profile/123 
        return false;
      }

      final isPublic = publicRoutes.any((r) => routeMatches(goingTo, r));

      // Estado inicial de chequeo
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

        // Si la ruta es pública, permitir (IMPORTANTE para compartir /terms-privacy)
        if (isPublic) return null;

        // Si intenta acceder a ruta privada → login
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

        // Rutas permitidas cuando perfil completo
        const allowedWhenComplete = {
          '/profile',
          '/profile-view',
          '/edit-profile',
          '/stats',
          '/search',
        };

        final allowed =
            allowedWhenComplete.any((r) => routeMatches(goingTo, r)) || isPublic;

        if (!allowed) {
          return '/profile';
        }
      }

      // Por defecto no redirigir
      return null;
    },

  );
}
