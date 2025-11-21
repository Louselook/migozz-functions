import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/functions/email_validation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    if (email.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Register.validations.emptyEmail".tr(),
        type: SnackbarType.error,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Validar formato de email
    final isValidEmail = validateCurrentField(
      botIndex: 20, // 20 corresponde a email
      userResponse: email,
    );

    if (!isValidEmail) {
      CustomSnackbar.show(
        context: context,
        message: "Register.validations.validationEmail".tr(),
        type: SnackbarType.error,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Verificar si el email ya existe
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final exists = await authService.emailExists(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (exists) {
        CustomSnackbar.show(
          context: context,
          message: "Register.validations.registerEmail".tr(),
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Email válido y disponible, navegar al chat de registro
      context.pushReplacement('/ia-chat', extra: email);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        CustomSnackbar.show(
          context: context,
          message: "Error verifying email: $e",
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

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
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 200),
                child: ConstrainedBox(
                  // ESTE ancho es lo que hace que se vea igual al login
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    // mismo padding horizontal que en LoginForm
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Logo(),
                          const SizedBox(height: 20),

                          // Welcome text
                          PrimaryText("Register.presentation.title".tr()),
                          const SizedBox(height: 3),
                          SecondaryText("Register.presentation.subtitle1".tr()),

                          const SizedBox(height: 30),

                          // Email input
                          CustomTextField(
                            hintText: "Register.presentation.inputText".tr(),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.secondaryText,
                            ),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted: (_) => _handleRegister(),
                          ),

                          const SizedBox(height: 35),

                          // Register button
                          GradientButton(
                            width: double.infinity,
                            radius: 19,
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : SecondaryText(
                                    "Register.presentation.buttonText".tr(),
                                    fontSize: 20, //  igual tamaño que en Login
                                  ),
                          ),
                        ],
                      ),
                    ),
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
                      TextSpan(
                        text: "Register.presentation.bottonText.login".tr(),
                      ),
                      gradientTextSpan(
                        "Register.presentation.bottonText.LoginReturn".tr(),
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
