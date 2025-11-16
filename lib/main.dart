// main.dart (modificado)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/services/social_auth_service.dart';
import 'package:migozz_app/email_otp_custom.dart';
import 'package:migozz_app/core/services/deeplink_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await configureDependencies();
  await FirebaseConfig.initialize();
  await dotenv.load(fileName: ".env");
  SocialAuthService().init();

  EmailOTP.config(
    appName: 'Migozz',
    otpType: OTPType.numeric,
    expiry: 30000,
    emailTheme: EmailTheme.v6,
    appEmail: 'me@rohitchouhan.com',
    otpLength: 6,
  );

  // 🧠 Crear instancias persistentes ANTES del runApp
  final authCubit = AuthCubit(locator.get(), locator.get());
  final registerCubit = RegisterCubit(locator.get());
  final goRouterNotifier = GoRouterNotifier(authCubit);

  // ← Crear el GoRouter una sola vez y reutilizarlo
  final router = createRouter(goRouterNotifier);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: registerCubit),
          BlocProvider<LoginCubit>(create: (_) => LoginCubit()),
          BlocProvider<EditCubit>(
            create: (context) => EditCubit(locator.get(), authCubit),
          ),
        ],
        child: MyApp(goRouter: router, goRouterNotifier: goRouterNotifier),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter goRouter;
  final GoRouterNotifier goRouterNotifier;
  const MyApp({
    super.key,
    required this.goRouter,
    required this.goRouterNotifier,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeeplinkService.initialize(context);
    });

    return AppInitializer(
      builder: (context, initResult) {
        if (initResult?.location != null) {
          context.read<RegisterCubit>().updateLocation(initResult!.location);
        }

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Migozz App',
          // ← usar la instancia creada arriba (no llamar createRouter aquí)
          routerConfig: goRouter,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
