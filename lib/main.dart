import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/bloc_providers.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/users/profile_deeplink_service.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_service.dart';
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
          final router = createRouter(goRouterNotifier);

          // 🔥 AGREGAR ESTA LÍNEA:
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

              final deviceLocale = context.locale;
              final deviceLang = deviceLocale.languageCode;
              final langLabel = deviceLang == 'es' ? 'Español' : 'English';

              GeminiService.instance.setLanguage(langLabel);

              if (initResult?.location != null) {
                // Navegar post-frame para esperar a que EasyLocalization y el árbol estén listos.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    final initialLocation =
                        Uri.base.path; // ESTA ES LA RUTA QUE QUEREMOS

                    // Evitamos navegar si es "/" o vacío
                    if (initialLocation.isNotEmpty && initialLocation != "/") {
                      debugPrint(
                        "➡️ Deep link real detectado: $initialLocation",
                      );
                      router.go(initialLocation);
                    }
                  } catch (e, st) {
                    debugPrint(
                      "⚠️ Error al navegar al deep link inicial: $e\n$st",
                    );
                  }
                });
              }

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Migozz App',
                routerConfig: router, // 👈 ahora es estable
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                  useMaterial3: true,
                ),
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
