import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/components/bottom_text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';
import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 20.0,
              left: 20.0,
              bottom: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/icons/Migozz@300x.png',
                  width: 99,
                  height: 98,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, color: Colors.white);
                  },
                ),

                const SizedBox(height: 16),

                // Welcome text
                const PrimaryText('Welcome to Migozz!'),

                const SizedBox(height: 3),

                const Text(
                  'Connect your Community',
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // Email input
                CustomTextField(
                  hintText: "Enter Email",
                  prefixIcon: const Icon(
                    Icons.email,
                    color: AppColors.secondaryText,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.sync),
                  ),
                  controller: _emailController,
                ),

                const SizedBox(height: 35),

                // Login button
                GradientButton(
                  width: double.infinity,
                  radius: 19,
                  // onPressed: authProvider.isLoading ? null : _handleLogin,
                  onPressed: () {
                    // Modificar avegacion
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OtpScreen(),
                      ),
                    );
                  },
                  child: SecondaryText('Login', fontSize: 20),
                ),

                const SizedBox(height: 40),

                const SecondaryText('Or login with', fontSize: 16),

                const SizedBox(height: 5),

                // Google login button
                googleButton(onPressed: () {}),

                const SizedBox(height: 50),

                // Register
                bottomText(context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
