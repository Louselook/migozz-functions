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
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/functions/email_validation.dart';

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
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context);

    try {
      final authCubit = context.read<AuthCubit>();
      final result = await authCubit
          .signInWithGoogle(); // devuelve SocialSignInResult

      if (!mounted) return;
      LoadingOverlay.hide(context);

      final email = result.credential.user?.email;

      if (!result.profileExists) {
        // Si no existe perfil en Firestore -> llevar a ia-chat para completar registro
        if (email != null && email.isNotEmpty) {
          // guardar email en RegisterCubit para que ia-chat pueda leerlo
          try {
            context.read<RegisterCubit>().setEmail(email);
          } catch (_) {
            // Si por alguna razón no existe el cubit, aún navegamos con extra
          }

          // Navegar a ia-chat pasando el email
          // uso context.go para evitar problemas con el redirect/stack
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

      // Si profileExists == true, no hacemos nada: la suscripción de AuthCubit
      // probablemente emitirá Authenticated y el router redirigirá al profile.
      // Si quieres forzar navegación:
      // context.go('/profile');
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

        if (state.errorMessageLogin != null) {
          // Limpiar error en el cubit para que no se repita
          context.read<LoginCubit>().clearError();
          CustomSnackbar.show(
            context: context,
            message: state.errorMessageLogin!,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
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

                        // ignore: non_constant_identifier_names
                        final Keyboardclose = FocusScope.of(context);
                        Keyboardclose.unfocus();

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
                    googleButton(onPressed: _handleGoogleSignIn),
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
