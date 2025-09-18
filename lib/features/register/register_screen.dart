import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/login_screen.dart';
import 'package:migozz_app/features/register/chat/ia_chat_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.link, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 20),

                // Welcome text
                const PrimaryText('Register Now!'),

                const SizedBox(height: 3),

                const SecondaryText('Enter your information below'),

                const SizedBox(height: 30),

                // Email input
                CustomTextField(
                  hintText: "Enter Email",
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.secondaryText,
                  ),
                  controller: _emailController,
                ),

                const SizedBox(height: 30),

                // Register button
                GradientButton(
                  width: double.infinity,
                  radius: 19,
                  onPressed: () {
                    // Modificar avegacion
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IaChatScreen(),
                      ),
                    );
                  },
                  child: SecondaryText("Create Account"),
                ),

                const Spacer(),

                // Login link
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    children: [
                      const TextSpan(text: "Already a member? "),
                      gradientTextSpan(
                        "Login",
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
