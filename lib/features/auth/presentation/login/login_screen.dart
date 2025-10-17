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
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
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

  // 🔹 Flags para evitar acciones repetidas
  bool _hasNavigatedToOTP = false;
  bool _isLoadingVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context);

    try {
      final authCubit = context.read<AuthCubit>();
      final result = await authCubit.signInWithGoogle();

      if (!mounted) return;
      LoadingOverlay.hide(context);

      final email = result.credential.user?.email;

      if (!result.profileExists) {
        if (email != null && email.isNotEmpty) {
          try {
            context.read<RegisterCubit>().setEmail(email);
          } catch (_) {
            // Si no existe el cubit, aún navegamos con extra
          }

          context.go('/ia-chat', extra: email);
          return;
        } else {
          CustomSnackbar.show(
            context: context,
            message: 'No se pudo obtener el email de Google.',
            type: SnackbarType.error,
          );
          return;
        }
      }
    } catch (e) {
      if (mounted) LoadingOverlay.hide(context);

      String message = 'Error al iniciar sesión con Google';
      if (e.toString().contains('cancelled_by_user')) {
        message = 'Inicio de sesión cancelado';
      }
      CustomSnackbar.show(
        context: context,
        message: message,
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // 🔹 Listener para LOADING
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
                    // Resetear flag cuando regrese
                    _hasNavigatedToOTP = false;
                  });
                }
              });
            }
          },
        ),

        // 🔹 Listener para ERRORES - Controlado para evitar duplicaciones
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            // 🔹 VOLVER a lógica que evita duplicaciones
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
                  Image.asset(
                    'assets/icons/Migozz300x.png',
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
                    keyboardType: TextInputType.emailAddress,
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

                      final keyboardClose = FocusScope.of(context);
                      keyboardClose.unfocus();

                      if (!isValidEmail) {
                        CustomSnackbar.show(
                          context: context,
                          message: "Please enter a valid email",
                          type: SnackbarType.error,
                        );
                        return;
                      }

                      // 🔹 Resetear flags antes de nueva operación
                      _hasNavigatedToOTP = false;

                      context.read<LoginCubit>().sendOTPLoginCubit(email);
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
