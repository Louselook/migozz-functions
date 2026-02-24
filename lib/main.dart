import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
import 'package:go_router/go_router.dart';
import 'core/services/ai/gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['STRIPE_PK'] ?? "";

  await EasyLocalization.ensureInitialized();

  // Cargar .env ANTES de configureDependencies para que ApiConfig tenga los valores
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('ℹ️ [Main] .env not found, using --dart-define variables');
  }

  await Stripe.instance.applySettings();
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
    // 1. Providers at the very top (persistent across simple rebuilds)
    MultiBlocProvider(
      providers: blocProviders,
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // Mobile base design
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('es')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: _getStartLocale(),
            // ScreenUtilInit rebuilds this builder on resize
            child: const MyApp(), // MyApp is now just the router container
          );
        },
      ),
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  static const Set<String> _reservedRootSegments = {
    'onboarding',
    'login',
    'register',
    'profile',
    'profile-view',
    'search',
    'edit-profile',
    'visual-edit',
    'policy-deleted',
    'terms-privacy',
    'support',
    'complete-profile',
    'ia-chat',
    'stats',
    'notifications',
    'followers',
    'chats',
    'chat',
    'splash',
    'u',
    'link',
  };

  bool _shouldNavigateToInitialLocation(String rawPath) {
    final normalized = rawPath.trim();
    if (normalized.isEmpty || normalized == '/') return false;

    final segments = Uri.parse(normalized).pathSegments;
    if (segments.isEmpty) return false;

    // /u/:username public profile link
    if (segments.length == 2 && segments.first == 'u') {
      return segments[1].isNotEmpty;
    }

    // /:username public profile link
    if (segments.length == 1) {
      final root = segments.first.toLowerCase();
      return root.isNotEmpty && !_reservedRootSegments.contains(root);
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    // ✅ Initialize Router ONCE.
    // AuthCubit is available from context because MultiBlocProvider is above.
    final goRouterNotifier = GoRouterNotifier(context.read<AuthCubit>());
    _router = createRouter(goRouterNotifier);

    ProfileDeeplinkService.setRouter(_router);

    // Initializations that happen once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicializar deeplinks solo en mobile
      if (!kIsWeb) {
        DeeplinkService.initialize(context);
      }

      // Manejar deep links iniciales (no depende de ubicación)
      try {
        final initialLocation = Uri.base.path;

        if (_shouldNavigateToInitialLocation(initialLocation)) {
          debugPrint("➡️ Deep link detectado: $initialLocation");
          _router.go(initialLocation);
        } else {
          debugPrint("ℹ️ Deep link inicial ignorado: $initialLocation");
        }
      } catch (e, st) {
        debugPrint("⚠️ Error al navegar al deep link inicial: $e\n$st");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppInitializer(
      builder: (context, initResult) {
        if (initResult?.location != null) {
          context.read<RegisterCubit>().updateLocation(initResult!.location);
        }

        // ✅ Configurar idioma para Gemini
        final deviceLocale = context.locale;
        final langLabel = deviceLocale.languageCode == 'es'
            ? 'Español'
            : 'English';

        debugPrint('🌐 Configurando Gemini con idioma: $langLabel');
        GeminiService.instance.setLanguage(langLabel);

        // 🆕 Escuchar cambios de autenticación para saber cuándo está listo
        return BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            // Solo para debugging
            debugPrint('🔐 [MyApp] Auth status changed: ${state.status}');
          },
          child: NotificationInitializer(
            router: _router,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Migozz App',
              routerConfig: _router,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  }
}
