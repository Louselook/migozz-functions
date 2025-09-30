import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:migozz_app/app_initializer.dart';
import 'package:migozz_app/bloc_providers.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/core/router/app_router.dart';
import 'package:migozz_app/core/router/app_router_notifier.dart';
import 'package:migozz_app/email_otp_custom.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await dotenv.load(fileName: ".env"); // inicialización

  // Config OTP
  EmailOTP.config(
    appName: 'Migozz',
    otpType: OTPType.numeric,
    expiry: 30000,
    emailTheme: EmailTheme.v6,
    appEmail: 'me@rohitchouhan.com',
    otpLength: 6,
  );

  runApp(const MyApp());
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

          return AppInitializer(
            builder: (context, initResult) {
              // initResult contiene permisos y ubicación; si quieres los metes en un Cubit aquí
              // Ejemplo: context.read<LocationCubit>().setLocation(initResult?.location);

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Migozz App',
                routerConfig: createRouter(goRouterNotifier), // tu GoRouter
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                  useMaterial3: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
