import 'package:flutter/material.dart';
import 'package:migozz_app/core/config/firebase_config.dart';
import 'package:migozz_app/email_otp_custom.dart';
import 'package:migozz_app/features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize(); // inicialización
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
    return MaterialApp(
      title: 'Migozz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
