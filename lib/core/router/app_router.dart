import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_screen.dart';
import 'package:migozz_app/features/profile/presentation/edit_profile.dart';
import 'package:migozz_app/features/profile/presentation/profile_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/ia_chat_screen.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

GoRouter createRouter(GoRouterNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: goRouterNotifier, // 🔑 clave
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return OtpScreen(email: data['email'], userOTP: data['userOTP']);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfile(),
      ),
      GoRoute(
        path: '/ia-chat',
        builder: (context, state) {
          // final email = state.extra as String;
          // ya existe un RegisterCubit arriba en el árbol
          context.read<RegisterCubit>().setEmail("juanes.arenilla@gmail.com");
          return const IaChatScreen();
        },
      ),
    ],
    redirect: (context, state) {
      final status = goRouterNotifier.authStatus;
      final goingTo = state.matchedLocation;

      // Rutas accesibles sin autenticación
      const publicRoutes = {
        '/login',
        '/register',
        '/onboarding',
        '/ia-chat',
        '/otp',
      };

      // Estado inicial (aún revisando auth)
      if (status == AuthStatus.checking) return null;

      // Usuario NO autenticado
      if (status == AuthStatus.notAuthenticated) {
        if (publicRoutes.contains(goingTo)) return null;
        return '/login';
      }

      // Usuario autenticado
      if (status == AuthStatus.authenticated) {
        if (publicRoutes.contains(goingTo)) return '/profile';
      }

      return null;
    },
  );
}
