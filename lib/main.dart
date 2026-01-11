import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/bloc_providers.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/users/profile_deeplink_service.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_service.dart';
import 'package:migozz_app/core/services/notifications/notification_initializer.dart';
import 'package:migozz_app/core/services/social_auth_service.dart';
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

  // ✅ Inicializar providers ANTES de runApp
  initializeBlocProviders();

  setPathUrlStrategy();
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('es')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: _getStartLocale(),
          child: child!,
        );
      },
      child: const MyApp(),
    ),
  );
}

/// ✅ Determina el locale inicial según el idioma del dispositivo
Locale _getStartLocale() {
  final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;

  // Si el idioma del dispositivo es español (cualquier variante)
  if (platformLocale.languageCode == 'es') {
    debugPrint(
      '🌍 Idioma detectado: Español (${platformLocale.toLanguageTag()})',
    );
    return const Locale('es');
  }

  // Para CUALQUIER otro idioma (chino, japonés, alemán, francés, etc.)
  debugPrint(
    '🌍 Idioma detectado: ${platformLocale.toLanguageTag()} → usando English',
  );
  return const Locale('en');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Usar providers estáticos que se crearon UNA SOLA VEZ
    return MultiBlocProvider(
      providers: blocProviders,
      child: Builder(
        builder: (context) {
          final goRouterNotifier = GoRouterNotifier(context.read<AuthCubit>());
          final router = createRouter(goRouterNotifier);

          ProfileDeeplinkService.setRouter(router);

          // Inicializar deeplinks solo en mobile
          if (!kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DeeplinkService.initialize(context);
            });
          }

          return AppInitializer(
            builder: (context, initResult) {
              if (initResult?.location != null) {
                context.read<RegisterCubit>().updateLocation(
                  initResult!.location,
                );
              }

              // ✅ Configurar idioma para Gemini
              final deviceLocale = context.locale;
              final langLabel = deviceLocale.languageCode == 'es'
                  ? 'Español'
                  : 'English';

              debugPrint('🌐 Configurando Gemini con idioma: $langLabel');
              GeminiService.instance.setLanguage(langLabel);

              // Manejar deep links iniciales (no depende de ubicación)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final initialLocation = Uri.base.path;

                  if (initialLocation.isNotEmpty && initialLocation != "/") {
                    debugPrint("➡️ Deep link detectado: $initialLocation");
                    router.go(initialLocation);
                  }
                } catch (e, st) {
                  debugPrint(
                    "⚠️ Error al navegar al deep link inicial: $e\n$st",
                  );
                }
              });

              return NotificationInitializer(
                router: router,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'Migozz App',
                  routerConfig: router,
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.deepPurple,
                    ),
                    useMaterial3: true,
                  ),
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
