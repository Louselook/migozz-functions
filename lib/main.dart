import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/bloc_providers.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/users/profile_deeplink_service.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_service.dart';
import 'package:migozz_app/core/services/notifications/notification_initializer.dart';
import 'package:migozz_app/core/services/notifications/notification_service.dart';
import 'package:migozz_app/core/services/social_auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/injection.dart';
import 'package:url_strategy/url_strategy.dart';
import 'core/services/ai/gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Cargar .env ANTES de configureDependencies para que ApiConfig tenga los valores
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('ℹ️ [Main] .env not found, using --dart-define variables');
  }

  await configureDependencies();
  await FirebaseConfig.initialize();

  // Register FCM background message handler ONCE globally
  // This MUST be done at the top level, not in a widget's initState
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ [Main] FCM background message handler registered globally');
  }
  SocialAuthService().init();

  // ✅ Inicializar providers ANTES de runApp
  initializeBlocProviders();

  // ✅ Initialize permission_handler for iOS
  // This ensures native permission dialogs work properly
  if (!kIsWeb) {
    try {
      // Just check status to initialize the handler
      await Permission.camera.status;
    } catch (e) {
      debugPrint('⚠️ [Main] Error initializing permission_handler: $e');
    }
  }

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

              // 🆕 Escuchar cambios de autenticación para saber cuándo está listo
              return BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  // Solo para debugging
                  debugPrint('🔐 [MyApp] Auth status changed: ${state.status}');
                },
                child: NotificationInitializer(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
