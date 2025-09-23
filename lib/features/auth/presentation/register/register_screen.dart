import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/ia_chat_screen.dart';

// Wrapper widget que proporciona el BlocProvider
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(),
      child: const _RegisterScreenContent(),
    );
  }
}

// Widget de contenido que puede acceder al cubit
class _RegisterScreenContent extends StatefulWidget {
  const _RegisterScreenContent();

  @override
  State<_RegisterScreenContent> createState() => _RegisterScreenContentState();
}

class _RegisterScreenContentState extends State<_RegisterScreenContent> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal centrado
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  right: 20,
                  left: 20,
                  bottom: 200,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.link,
                          color: Colors.white,
                          size: 40,
                        ),
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
                          final email = _emailController.text.trim();

                          if (email.isEmpty) {
                            CustomSnackbar.show(
                              context: context,
                              message: "Please enter an email",
                              type: SnackbarType.error,
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }

                          // Ahora sí puedes acceder al cubit
                          final cubit = context.read<RegisterCubit>();
                          cubit.setEmail(email);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => RegisterCubit()
                                  ..setEmail(email), // Inicializas con el email
                                child: const IaChatScreen(),
                              ),
                            ),
                          );
                        },
                        child: const SecondaryText("Create Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Link abajo fijo
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: screenHeight < 800 ? 130 : 220,
                ),
                child: RichText(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
