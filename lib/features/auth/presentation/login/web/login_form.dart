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
import 'package:migozz_app/features/auth/components/apple_button.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/email_validation.dart';
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

  Future<void> _handleAppleSignIn() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context);
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithApple();
    } catch (e) {
      debugPrint('error: $e');
      if (!e.toString().contains('cancelled_by_user')) {
        CustomSnackbar.show(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Error al iniciar sesión con Apple: $e',
          type: SnackbarType.error,
        );
      }
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
          mainAxisSize: MainAxisSize.min, //  importante para mobile
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onSubmitted: (_) => _handleEmailLoginCheck(),
            ),
            const SizedBox(height: 35),

            GradientButton(
              width: double.infinity,
              radius: 19,
              onPressed: _isCheckingEmail ? null : _handleEmailLoginCheck,
              child: const SecondaryText('Login', fontSize: 20),
            ),

            const SizedBox(height: 40),
            const SecondaryText('Or login with', fontSize: 16),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                googleButton(onPressed: _handleGoogleSignIn),
                const SizedBox(width: 10),
                appleButton(onPressed: _handleAppleSignIn),
              ],
            ),
            const SizedBox(height: 50),

            bottomText(context: context),
          ],
        ),
      ),
    );
  }
}
