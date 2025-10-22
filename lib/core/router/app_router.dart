import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';
import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
// import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_screen.dart';
import 'package:migozz_app/features/profile/presentation/edit/edit_profile_screen.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/complete_profile.dart';
import 'package:migozz_app/features/profile/presentation/profile/profile_screen.dart';
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
      };

      // Estado inicial de chequeo
      if (status == AuthStatus.checking) {
        return null;
      }

      // ========================
      // 🧩 1. Usuario NO autenticado
      // ========================
      if (status == AuthStatus.notAuthenticated) {
        // Si está en registro activo → ir al chat
        final isInRegisterFlow =
            registerState.regProgress != RegisterStatusProgress.emty &&
            registerState.regProgress != RegisterStatusProgress.doneChat;

        if (isInRegisterFlow) {
          if (goingTo != '/ia-chat') return '/ia-chat';
          return null;
        }

        // Si intenta acceder a rutas privadas → enviarlo al login
        if (!publicRoutes.contains(goingTo)) {
          return '/login';
        }
        return null;
      }

      // ========================
      // 🧩 2. Usuario autenticado
      // ========================
      if (status == AuthStatus.authenticated) {
        final userProfile = authState.userProfile;
        final hasActiveRegistration =
            registerState.regProgress != RegisterStatusProgress.emty &&
            registerState.regProgress != RegisterStatusProgress.doneChat;

        // 🟣 Caso: hay un flujo de registro activo
        if (hasActiveRegistration) {
          if (goingTo != '/ia-chat') return '/ia-chat';
          return null;
        }

        // 🟡 Caso: perfil no completo (pero ya autenticado)
        if (userProfile == null || !userProfile.complete) {
          if (goingTo != '/complete-profile' && goingTo != '/ia-chat') {
            return '/complete-profile';
          }
          return null;
        }

        // 🟢 Caso: perfil completo — siempre va al perfil
        if (userProfile.complete) {
          if (goingTo != '/profile') {
            return '/profile';
          } else {}
        }
      }

      // ========================
      // ✅ 3. Por defecto, no redirigir
      // ========================
      return null;
    },
  );
}
