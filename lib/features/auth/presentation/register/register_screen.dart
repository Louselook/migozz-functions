import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_validation.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';

// Wrapper widget que proporciona el BlocProvider
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(AuthService(), LocationService()),
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
      resizeToAvoidBottomInset: false,
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
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 30),

                      // Register button
                      GradientButton(
                        width: double.infinity,
                        radius: 19,
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          // ignore: non_constant_identifier_names
                          final Keyboardclose = FocusScope.of(context);
                          Keyboardclose.unfocus();
                          if (email.isEmpty) {
                            CustomSnackbar.show(
                              context: context,
                              message: "Email cannot be empty",
                              type: SnackbarType.error,
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }
                          // Validamos usando tu función
                          final isValidEmail = validateCurrentField(
                            botIndex: 20, // 20 corresponde a email
                            userResponse: email, // pasamos el valor del input
                          );

                          if (!isValidEmail) {
                            CustomSnackbar.show(
                              context: context,
                              message: "Please enter a valid email",
                              type: SnackbarType.error,
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }

                          // Validar existencia (async)
                          final exists = await AuthService().emailExists(email);
                          if (exists) {
                            debugPrint("Si existe :D");
                            CustomSnackbar.show(
                              // ignore: use_build_context_synchronously
                              context: context,
                              message: "This email is already registered",
                              type: SnackbarType.error,
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }

                          // Email válido, vamos al chat
                          // ignore: use_build_context_synchronously
                          context.pushReplacement('/ia-chat', extra: email);
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
                          context.go('/login');
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
