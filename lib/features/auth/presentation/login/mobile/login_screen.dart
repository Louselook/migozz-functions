import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/components/bottom_text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';
import 'package:migozz_app/features/auth/components/apple_button.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/login/shared/login_wrapper.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/email_validation.dart';

import '../../../../../core/utils/platform_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    // Validaciones básicas
    if (email.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "login.validations.emptyEmail".tr(),
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
        message: "login.validations.invalidEmail".tr(),
        type: SnackbarType.error,
      );
      return;
    }

    if (_isCheckingEmail) return; // evita reentradas
    setState(() => _isCheckingEmail = true);

    // Muestra overlay de carga (esto es para la verificación con AuthService)
    LoadingOverlay.show(context);

    try {
      final authService = AuthService();
      final exists = await authService.emailExists(email);

      if (!mounted) return;

      if (!exists) {
        // Si NO existe, mostramos snackbar y NO continuamos
        CustomSnackbar.show(
          context: context,
          message: "login.validations.notExistEmail".tr(),
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      //  TODO: test user
      if (email.toLowerCase() == 'testuser@migozz.com') {
        const testOtp = '672183'; // OTP hardcodeado

        // En vez de loguear directamente, inyectamos el OTP al LoginCubit
        // para que el flujo normal de OTP se dispare (y LoginWrapper navegue).
        context.read<LoginCubit>().sendOTPLoginCubit(email, forcedOTP: testOtp);

        // Salimos: LoginWrapper escuchará currentOTP y hará la navegación.
        return;
      }

      // Si existe -> continuar con el flujo de login: enviamos OTP por el LoginCubit
      // Resetear flags por si acaso
      context.read<LoginCubit>().sendOTPLoginCubit(email);
    } catch (e) {
      // Manejo de errores de red / firestore
      CustomSnackbar.show(
        context: context,
        message: "${"login.validations.validationEmail".tr()}$e",
        type: SnackbarType.error,
      );
    } finally {
      // Oculta loader y libera flag
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isCheckingEmail = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context);

    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithGoogle();

      if (!mounted) return;
    } catch (e) {
      debugPrint("error: $e");

      // Evita mostrar errores genéricos o warnings de Firebase
      final msg = e.toString();
      if (!msg.contains("AppCheckProvider") &&
          !msg.contains("ProviderInstaller")) {
        CustomSnackbar.show(
          context: context,
          message: "login.validations.cancelledGoogle".tr(),
          type: SnackbarType.error,
        );
      }
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

      if (!mounted) return;
    } catch (e) {
      debugPrint("error: $e");

      // Evita mostrar errores genéricos o warnings de Firebase
      final msg = e.toString();
      if (!msg.contains("AppCheckProvider") &&
          !msg.contains("ProviderInstaller") &&
          !msg.contains("cancelled_by_user")) {
        CustomSnackbar.show(
          context: context,
          message: "login.validations.cancelledApple".tr(),
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envuelve tu layout con LoginWrapper para heredar listeners compartidos
    return LoginWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        resizeToAvoidBottomInset: false,
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
                  Logo(),

                  const SizedBox(height: 16),

                  // Welcome text
                  // "login.presentation.title".tr()
                  PrimaryText("login.presentation.title".tr()),

                  const SizedBox(height: 3),

                  Text(
                    "login.presentation.subtitle1".tr(),
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 40),

                  // Email input
                  CustomTextField(
                    hintText: "login.presentation.inputText".tr(),
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

                  const SizedBox(height: 15),

                  // Login button
                  GradientButton(
                    width: double.infinity,
                    radius: 19,
                    onPressed: _isCheckingEmail
                        ? null
                        : () {
                            _handleEmailLoginCheck();
                          },
                    child: SecondaryText(
                      "login.presentation.buttonText".tr(),
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SecondaryText(
                    "login.presentation.subtitle2".tr(),
                    fontSize: 16,
                  ),

                  const SizedBox(height: 5),
                  // Social login buttons
                  PlatformUtils.isIOS
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            googleButton(onPressed: _handleGoogleSignIn),
                            const SizedBox(width: 10),
                            appleButton(onPressed: _handleAppleSignIn),
                          ],
                        )
                      : Center(
                          child: googleButton(onPressed: _handleGoogleSignIn),
                        ),

                  const SizedBox(height: 30),

                  // Register
                  bottomText(context: context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
