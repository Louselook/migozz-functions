// lib/features/auth/presentation/login/web/login_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/components/bottom_text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/email_validation.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isCheckingEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLoginCheck() async {
    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();

    if (email.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Email cannot be empty",
        type: SnackbarType.error,
      );
      return;
    }

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

    if (_isCheckingEmail) return;
    setState(() => _isCheckingEmail = true);

    // Dejar que el LoginCubit maneje el loading/OTP (LoginWrapper escucha LoginCubit)
    try {
      final authService = AuthService();
      final exists = await authService.emailExists(email);

      if (!mounted) return;

      if (!exists) {
        CustomSnackbar.show(
          context: context,
          message:
              "This email is not registered. Please create an account first.",
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Si existe -> solicita el OTP (el LoginCubit debe poner isLoading=true y emitir currentOTP)
      context.read<LoginCubit>().sendOTPLoginCubit(email);
    } catch (e) {
      CustomSnackbar.show(
        context: context,
        message: "Error verifying email: $e",
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context);
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithGoogle();
    } catch (e) {
      debugPrint('error: $e');
      // ignore: use_build_context_synchronously
      CustomSnackbar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Error al iniciar sesión con Google: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 35),

            // Login button
            GradientButton(
              width: double.infinity,
              radius: 19,
              onPressed: _isCheckingEmail ? null : _handleEmailLoginCheck,
              child: const SecondaryText('Login', fontSize: 20),
            ),

            const SizedBox(height: 40),
            const SecondaryText('Or login with', fontSize: 16),
            const SizedBox(height: 5),

            // Google login button
            googleButton(onPressed: _handleGoogleSignIn),
            const SizedBox(height: 50),

            // Register
            bottomText(context: context),
          ],
        ),
      ),
    );
  }
}
