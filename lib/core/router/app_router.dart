import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
// import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_screen.dart';
import 'package:migozz_app/features/edit/presentation/edit_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/complete_profile.dart';
import 'package:migozz_app/features/profile/presentation/profile_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/ia_chat_screen.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
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
        if (context.read<RegisterCubit>().state.regProgress !=
            RegisterStatusProgress.emty) {
          return '/ia-chat';
        }
        return '/login';
      }

      // Usuario autenticado
      if (status == AuthStatus.authenticated) {
        final authState = context.read<AuthCubit>().state;
        final registerState = context.read<RegisterCubit>().state;

        // 🔑 NUEVO: Verificar si hay un proceso de registro activo
        final hasActiveRegistration =
            registerState.regProgress != RegisterStatusProgress.emty &&
            registerState.regProgress != RegisterStatusProgress.doneChat;

        // Si hay un proceso de registro activo y no está yendo a ia-chat, redirigir a ia-chat
        if (hasActiveRegistration && goingTo != '/ia-chat') {
          return '/ia-chat';
        }

        // Si necesita completar perfil, NO hay registro activo, y no está yendo a ia-chat
        if (authState.needsCompletion &&
            !hasActiveRegistration &&
            goingTo != '/ia-chat') {
          return '/complete-profile';
        }

        // Si el perfil está completo y está en ia-chat (sin registro activo), redirigir a profile
        if (!authState.needsCompletion &&
            goingTo == '/ia-chat' &&
            !hasActiveRegistration) {
          return '/profile';
        }

        // Si está yendo a rutas públicas y tiene perfil completo, redirigir a profile
        if (publicRoutes.contains(goingTo) && !authState.needsCompletion) {
          return '/profile';
        }
      }

      return null;
    },
  );
}
