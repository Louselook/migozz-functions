import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/components/bottom_text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/login/otp_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/email_validation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _hasNavigatedToOTP = false;
  bool _isLoadingVisible = false;
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

    if (_isCheckingEmail) return; // evita reentradas
    setState(() => _isCheckingEmail = true);

    // Muestra overlay de carga (coincide con tu estilo actual)
    LoadingOverlay.show(context);

    try {
      final authService = AuthService();
      final exists = await authService.emailExists(email);

      if (!mounted) return;

      if (!exists) {
        // Si NO existe, mostramos snackbar y NO continuamos
        CustomSnackbar.show(
          context: context,
          message:
              "This email is not registered. Please create an account first.",
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Si existe -> continuar con el flujo de login: enviamos OTP por el LoginCubit
      // Resetear flags por si acaso
      _hasNavigatedToOTP = false;
      context.read<LoginCubit>().sendOTPLoginCubit(email);
    } catch (e) {
      // Manejo de errores de red / firestore
      CustomSnackbar.show(
        context: context,
        message: "Error verifying email: $e",
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
      LoadingOverlay.hide(context);
    } catch (e) {
      debugPrint("error: $e");
      if (mounted) LoadingOverlay.hide(context);

      // Evita mostrar errores genéricos o warnings de Firebase
      final msg = e.toString();
      if (!msg.contains("AppCheckProvider") &&
          !msg.contains("ProviderInstaller")) {
        CustomSnackbar.show(
          context: context,
          message: 'Error al iniciar sesión con Google: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // 🔹 Listener para LOADING del LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return previous.isLoading != current.isLoading;
          },
          listener: (context, state) {
            if (state.isLoading && !_isLoadingVisible) {
              _isLoadingVisible = true;
              LoadingOverlay.show(context);
            } else if (!state.isLoading && _isLoadingVisible) {
              _isLoadingVisible = false;
              LoadingOverlay.hide(context);
            }
          },
        ),

        // 🔹 Listener para NAVEGACIÓN A OTP
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return previous.currentOTP != current.currentOTP &&
                current.currentOTP != null &&
                current.email != null;
          },
          listener: (context, state) {
            if (state.currentOTP != null &&
                state.email != null &&
                !_hasNavigatedToOTP) {
              _hasNavigatedToOTP = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => OtpScreen(
                        email: state.email!,
                        userOTP: state.currentOTP!,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  ).then((_) {
                    _hasNavigatedToOTP = false;
                  });
                }
              });
            }
          },
        ),

        // 🔹 Listener para ERRORES del LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return previous.errorMessageLogin != current.errorMessageLogin &&
                current.errorMessageLogin != null &&
                current.errorMessageLogin!.isNotEmpty;
          },
          listener: (context, state) {
            CustomSnackbar.show(
              context: context,
              message: state.errorMessageLogin!,
              type: SnackbarType.error,
            );
          },
        ),

        // 🔹 Listener para ÉXITO en AuthCubit (cuando se complete el login real)
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) {
            return current.isAuthenticated &&
                current.userProfile != null &&
                !previous.isAuthenticated;
          },
          listener: (context, state) {
            if (state.userProfile != null) {
              context.go('/profile', extra: state.userProfile!.email);
            }
          },
        ),
      ],
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
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 35),

                  // Login button
                  GradientButton(
                    width: double.infinity,
                    radius: 19,
                    onPressed: _isCheckingEmail
                        ? null
                        : () {
                            _handleEmailLoginCheck();
                          },
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
          ),
        ),
      ),
    );
  }
}
