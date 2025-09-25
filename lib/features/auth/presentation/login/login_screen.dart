import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/components/bottom_text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_validation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? myOTP;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingOverlay.show(context);
        } else {
          LoadingOverlay.hide(context);
        }

        if (state.currentOTP != null) {
          context.push(
            '/otp',
            extra: {'email': state.email, 'userOTP': state.currentOTP},
          );
        }

        if (state.errorMessage != null) {
          // Limpiar error en el cubit para que no se repita
          context.read<LoginCubit>().clearError();
          CustomSnackbar.show(
            context: context,
            message: state.errorMessage!,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
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
                      onPressed: () {
                        final email = _emailController.text.trim();

                        // Valida email
                        final isValidEmail = validateCurrentField(
                          botIndex: 20,
                          userResponse: email,
                        );

                        if (!isValidEmail) {
                          CustomSnackbar.show(
                            context: context,
                            message: "Please enter a valid email",
                            type: SnackbarType.error,
                          );
                          return;
                        }

                        context.read<LoginCubit>().sendOTPLoginCubit(email);
                      },
                      child: const SecondaryText('Login', fontSize: 20),
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
      },
    );
  }
}
