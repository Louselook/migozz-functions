import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/bloc_providers.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_service.dart';
import 'package:migozz_app/core/services/social_auth_service.dart';
import 'package:migozz_app/email_otp_custom.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/injection.dart';
import 'package:url_strategy/url_strategy.dart';

import 'core/services/ai/gemini_service.dart';

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

  setPathUrlStrategy();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: Builder(
        builder: (context) {
          final goRouterNotifier = GoRouterNotifier(context.read<AuthCubit>());

          // 🔹 Inicializar deeplinks después del primer frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DeeplinkService.initialize(context);
          });

          final router = createRouter(goRouterNotifier);

          return AppInitializer(
            builder: (context, initResult) {
              if (initResult?.location != null) {
                context.read<RegisterCubit>().updateLocation(
                  initResult!.location,
                );
              }
              final deviceLocale = context.locale;
              final deviceLang = deviceLocale.languageCode; // 'es' o 'en'
              final langLabel = deviceLang == 'es' ? 'Español' : 'English';

              // context.read<RegisterCubit>().setLanguage(langLabel);

              GeminiService.instance.setLanguage(langLabel);

              return MaterialApp.router(
                routerConfig: router,
                debugShowCheckedModeBanner: false,
                title: 'Migozz App',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                  useMaterial3: true,
                ),
                //  Esto es lo importante
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              );
            },
          );
        },
      ),
    );
  }
}
