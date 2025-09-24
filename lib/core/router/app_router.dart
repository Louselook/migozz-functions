import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/ia_chat_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/onboarding_screen.dart';
import 'package:migozz_app/features/profile/pages/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation:
      '/onboarding', // pued ser splash screen de una animacion o algo
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    // Ya está logueado
    if (user != null) {
      return '/profile';
    }

    // No por defecto onboarding
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) => OtpScreen.fromExtra(context),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    // chat
    GoRoute(
      path: '/ia-chat',
      builder: (context, state) {
        final email = state.extra as String;
        return BlocProvider(
          create: (context) => RegisterCubit()..setEmail(email),
          child: const IaChatScreen(),
        );
      },
    ),
  ],
);
