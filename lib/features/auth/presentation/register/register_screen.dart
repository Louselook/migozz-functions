import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
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
        message: "register.validations.emptyEmail".tr(),
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
        message: "register.validations.validationEmail".tr(),
        type: SnackbarType.error,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Verificar si el email ya existe o es pre-registro
    setState(() {
      _isLoading = true;
    });

    try {
      final registerCubit = context.read<RegisterCubit>();

      // Primero verificar si es un pre-registro
      final isPreRegistered = await registerCubit.checkPreRegister(email);

      if (!mounted) return;

      // Si NO es pre-registro, verificar si el email ya existe como usuario real
      if (!isPreRegistered) {
        final authService = AuthService();
        final exists = await authService.emailExists(email);

        if (!mounted) return;

        if (exists) {
          setState(() {
            _isLoading = false;
          });
          CustomSnackbar.show(
            context: context,
            message: "register.validations.registerEmail".tr(),
            type: SnackbarType.error,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Navegar al chat de registro (el cubit ya tiene el username si era pre-registro)
      context.pushReplacement('/ia-chat', extra: email);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        CustomSnackbar.show(
          context: context,
          message: '${"register.validations.errorVerify".tr()}$e',
          type: SnackbarType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // ── Logo section (reutilizable en mobile / desktop) ──
  Widget _buildLogoSection(double logoSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(width: logoSize, height: logoSize),
        const SizedBox(height: 20),
        PrimaryText(
          "register.presentation.title".tr(),
          fontSize: 22,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SecondaryText(
          "register.presentation.subtitle1".tr(),
          fontSize: 14,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Formulario de registro ──
  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email input
          CustomTextField(
            hintText: "register.presentation.inputText".tr(),
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
                    "register.presentation.buttonText".tr(),
                    fontSize: 17,
                  ),
          ),
          const SizedBox(height: 24),

          // Link to login
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              children: [
                TextSpan(text: "register.presentation.bottonText.login".tr()),
                gradientTextSpan(
                  "register.presentation.bottonText.LoginReturn".tr(),
                  onTap: () {
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Layout móvil (columna) ──
  Widget _buildMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoSize = (width * 0.35).clamp(120.0, 180.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoSection(logoSize),
          const SizedBox(height: 40),
          _buildRegisterForm(),
        ],
      ),
    );
  }

  // ── Layout desktop / web (logo izquierda, formulario derecha) ──
  Widget _buildDesktopLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final formWidth = (width * 0.28).clamp(340.0, 420.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLogoSection(250),
            ),
          ),
          const SizedBox(width: 32),
          SizedBox(width: formWidth, child: _buildRegisterForm()),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                child: isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
              ),
            );
          },
        ),
      ),
    );
  }
}
