import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // 🧠 Creamos instancias persistentes
  final authCubit = AuthCubit(locator.get());
  final registerCubit = RegisterCubit(locator.get());
  final goRouterNotifier = GoRouterNotifier(authCubit);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiBlocProvider(
        providers: [
          // Reusamos las instancias persistentes
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: registerCubit),

          // Reagregamos los demás blocProviders excepto esos dos
          // (copiados de tu bloc_providers.dart)
          BlocProvider<LoginCubit>(create: (_) => LoginCubit()),
          BlocProvider<EditCubit>(
            create: (context) => EditCubit(locator.get(), authCubit),
          ),
        ],
        child: MyApp(goRouterNotifier: goRouterNotifier),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouterNotifier goRouterNotifier;
  const MyApp({super.key, required this.goRouterNotifier});

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
          routerConfig: createRouter(goRouterNotifier),
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
