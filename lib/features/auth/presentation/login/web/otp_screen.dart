import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';

/// Pantalla de OTP web que replica la lógica de OTP móvil.
///
/// Contrato:
/// - Entradas: el constructor requiere [email] y [userOTP] (el OTP enviado).
/// - Salidas: llama a [LoginCubit.validateOTP] para validar el código localmente y, a continuación, llama a [AuthCubit.login(email, otp)] para realizar la autenticación.
/// - Modos de error: muestra barras de información para errores de OTP y de autenticación.
class OtpScreen extends StatefulWidget {
  final String email;
  final String userOTP;

  const OtpScreen({super.key, required this.email, required this.userOTP});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final FocusNode _firstFocusNode = FocusNode();

  bool _isLoadingVisible = false;
  bool _hasProcessedAuth = false;

  // concatenar el código OTP desde los controladores

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _firstFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleOtpCompletion(String otp) async {
    if (_hasProcessedAuth) return;

    final loginCubit = context.read<LoginCubit>();

    // Validar OTP localmente primero (esto actualizará el estado de LoginCubit y puede emitir errores)
    final isValid = await loginCubit.validateOTP(inputOTP: otp);
    if (!isValid) return;

    _hasProcessedAuth = true;

    // llamar a AuthCubit para realizar la autenticación.
    try {
      // ignore: use_build_context_synchronously
      await context.read<AuthCubit>().login(email: widget.email, otp: otp);
    } catch (e) {
      // Propagate to LoginCubit so UI shows it consistently
      loginCubit.setAuthenticationError(e.toString());
      _hasProcessedAuth = false;
    }
  }

  void _clearFields() {
    for (final c in _controllers) {
      c.clear();
    }
    // Volver a enfocar el primer campo
    _firstFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // mostrar/ocultar loading overlay basado en LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (prev, cur) => prev.isLoading != cur.isLoading,
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

        // OTP errors: mostrar snackbar y limpiar
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (prev, cur) => prev.otpErrorCount != cur.otpErrorCount,
          listener: (context, state) {
            if (state.errorMessageOTP != null &&
                state.errorMessageOTP!.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              CustomSnackbar.show(
                context: context,
                message: state.errorMessageOTP!,
                type: SnackbarType.error,
              );
              _clearFields();
              _hasProcessedAuth = false;
            }
          },
        ),

        // autenticación: errores propagados via LoginCubit.errorMessageLogin
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (prev, cur) =>
              prev.errorMessageLogin != cur.errorMessageLogin,
          listener: (context, state) {
            if (state.errorMessageLogin != null &&
                state.errorMessageLogin!.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              CustomSnackbar.show(
                context: context,
                message: state.errorMessageLogin!,
                type: SnackbarType.error,
              );
              _hasProcessedAuth = false;
            }
          },
        ),

        // ✅ LISTENER FIX: Redirigir al perfil cuando la autenticación es exitosa
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, cur) => prev.status != cur.status,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              _hasProcessedAuth = true; // prevent any further attempts
              context.go('/profile');
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFEAE7F0),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              final aspectRatio = screenHeight / screenWidth;
              final bool isDesktop = screenWidth >= 900;
              final bool isLarge = screenWidth >= 768;
              final bool isCompact = screenWidth < 400;
              final bool isVeryTallScreen = aspectRatio > 2.0;
              final double spacing = isLarge ? 16 : (isCompact ? 6 : 10);

              if (isDesktop) {
                // Layout de dos columnas para desktop
                return Row(
                  children: [
                    // Lado izquierdo - Imagen con gradiente
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: screenHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFD43AB6),
                              const Color(0xFF9321BD),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Botón de volver
                            Positioned(
                              top: 24,
                              left: 24,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  context.read<LoginCubit>().resetState();
                                  context.pop();
                                },
                              ),
                            ),
                            // Contenido central
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/otp_image.webp',
                                    width: 320,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 32),
                                  const PrimaryText(
                                    'Verify Your Identity',
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  const SecondaryText(
                                    'Enter the code sent to your email',
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Lado derecho - Contenido
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PrimaryText(
                                  'Enter OTP Code',
                                  color: AppColors.backgroundDark,
                                  fontSize: 36,
                                ),
                                const SizedBox(height: 12),
                                SecondaryText(
                                  'OTP code has been sent to ${widget.email}',
                                  color: AppColors.greyBackground,
                                  fontSize: 14,
                                ),
                                const SizedBox(height: 40),
                                _buildOtpFields(
                                  isLarge,
                                  isCompact,
                                  isVeryTallScreen,
                                  spacing,
                                  isDesktop: false,
                                ),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _controllers
                                                .map((c) => c.text)
                                                .join()
                                                .length ==
                                            6
                                        ? () => _handleOtpCompletion(
                                            _controllers
                                                .map((c) => c.text)
                                                .join(),
                                          )
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: AppColors
                                          .primaryGradient
                                          .colors
                                          .first,
                                    ),
                                    child: const Text(
                                      'Verify',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Layout móvil/tablet
              final double contentWidth = (screenWidth * 0.9).clamp(
                280.0,
                520.0,
              );

              return Stack(
                children: [
                  // Botón de volver para móvil
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.backgroundDark,
                        size: 22,
                      ),
                      onPressed: () {
                        context.read<LoginCubit>().resetState();
                        context.pop();
                      },
                    ),
                  ),
                  // Contenido
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: screenHeight),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 20,
                            vertical: isVeryTallScreen ? 16 : 24,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Espacio para el botón de volver
                                const SizedBox(height: 40),
                                PrimaryText(
                                  'Enter OTP Code',
                                  color: AppColors.backgroundDark,
                                  fontSize: isCompact ? 28 : 36,
                                ),
                                SizedBox(height: isCompact ? 4 : 8),
                                SecondaryText(
                                  'OTP code has been sent to ${widget.email}',
                                  color: AppColors.greyBackground,
                                  fontSize: isCompact ? 11 : 13,
                                ),
                                SizedBox(
                                  height: isVeryTallScreen
                                      ? 20
                                      : (isCompact ? 24 : 40),
                                ),

                                // OTP fields + resend - layout mejorado para móvil
                                _buildOtpFields(
                                  isLarge,
                                  isCompact,
                                  isVeryTallScreen,
                                  spacing,
                                ),

                                SizedBox(
                                  height: isVeryTallScreen
                                      ? 20
                                      : (isCompact ? 24 : 36),
                                ),

                                Align(
                                  child: Image.asset(
                                    'assets/images/otp_image.webp',
                                    width: isVeryTallScreen
                                        ? 160
                                        : (isLarge
                                              ? 300
                                              : (isCompact ? 160 : 200)),
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                SizedBox(
                                  height: isVeryTallScreen
                                      ? 16
                                      : (isCompact ? 20 : 28),
                                ),

                                Align(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isLarge
                                          ? 420
                                          : (isCompact ? 280 : 380),
                                      minWidth: 200,
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _controllers
                                                  .map((c) => c.text)
                                                  .join()
                                                  .length ==
                                              6
                                          ? () => _handleOtpCompletion(
                                              _controllers
                                                  .map((c) => c.text)
                                                  .join(),
                                            )
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isCompact
                                              ? 12
                                              : (isLarge ? 18 : 14),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        backgroundColor: AppColors
                                            .primaryGradient
                                            .colors
                                            .first,
                                      ),
                                      child: Text(
                                        'Verify',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isCompact ? 16 : 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isVeryTallScreen ? 16 : 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields(
    bool isLarge,
    bool isCompact,
    bool isVeryTallScreen,
    double spacing, {
    bool isDesktop = false,
  }) {
    // Calcular tamaño de los campos OTP
    final double boxSize = isDesktop
        ? 56
        : (isVeryTallScreen ? 40 : (isCompact ? 42 : 48));
    final double fieldSpacing = isDesktop ? 14 : (isLarge ? 12 : spacing);

    if (isCompact || isVeryTallScreen) {
      // Layout vertical para móviles estrechos
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i < 5 ? fieldSpacing : 0),
                child: _OtpBoxField(
                  size: boxSize,
                  controller: _controllers[i],
                  focusNode: i == 0 ? _firstFocusNode : null,
                  isFirst: i == 0,
                  index: i,
                  onChanged: (v) => _handleOtpChange(v, i),
                  onSubmitted: (_) => _submitOtp(),
                  isDarkMode: isDesktop,
                ),
              );
            }),
          ),
          SizedBox(height: isVeryTallScreen ? 8 : 12),
          TextButton(
            onPressed: () => context.read<LoginCubit>().sendOTPLoginCubit(
              widget.email,
              language: context.locale.languageCode,
            ),
            child: SecondaryText(
              'Resend',
              color: isDesktop ? Colors.white70 : AppColors.greyBackground,
              fontSize: isCompact ? 12 : 13,
            ),
          ),
        ],
      );
    }

    // Layout para pantallas más anchas
    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: isDesktop
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 5 ? fieldSpacing : 0),
              child: _OtpBoxField(
                size: boxSize,
                controller: _controllers[i],
                focusNode: i == 0 ? _firstFocusNode : null,
                isFirst: i == 0,
                index: i,
                onChanged: (v) => _handleOtpChange(v, i),
                onSubmitted: (_) => _submitOtp(),
                isDarkMode: isDesktop,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.read<LoginCubit>().sendOTPLoginCubit(
            widget.email,
            language: context.locale.languageCode,
          ),
          child: SecondaryText(
            'Resend',
            color: isDesktop ? Colors.white70 : AppColors.greyBackground,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _handleOtpChange(String v, int i) {
    // Filtrar solo dígitos
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 1) {
      // Handle paste: distribuir dígitos empezando desde el campo actual
      for (int j = 0; j < digits.length && (i + j) < 6; j++) {
        _controllers[i + j].text = digits[j];
      }

      // Mover foco al campo después del último dígito pegado o al final
      final lastIndex = (i + digits.length - 1).clamp(0, 5);
      if (lastIndex < 5) {
        // Mover al siguiente campo después del último pegado
        FocusScope.of(context).unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
        });
      } else {
        FocusScope.of(context).unfocus();
      }

      // Verificar si el código está completo
      final code = _controllers.map((c) => c.text).join();
      if (code.length == 6) {
        _handleOtpCompletion(code);
      }
    } else if (digits.length == 1) {
      // Un solo dígito: asegurar que solo hay uno en el campo
      _controllers[i].text = digits;
      _controllers[i].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
    }

    setState(() {});

    // Verificar si el código está completo
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      FocusScope.of(context).unfocus();
      _handleOtpCompletion(code);
    }
  }

  void _submitOtp() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _handleOtpCompletion(code);
    }
  }
}

class _OtpBoxField extends StatelessWidget {
  final double size;
  final TextEditingController controller;
  final int index;
  final bool isFirst;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isDarkMode;

  const _OtpBoxField({
    required this.size,
    required this.controller,
    required this.index,
    required this.isFirst,
    this.focusNode,
    required this.onChanged,
    this.onSubmitted,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: isFirst,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        showCursor: false,
        // No usar maxLength para permitir pegado de múltiples dígitos
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white54 : const Color(0xFFC5CAD3),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white : const Color(0xFF9321BD),
              width: 1.6,
            ),
          ),
        ),
        onChanged: (value) {
          // Primero pasar el valor completo al handler principal para manejar pegado
          onChanged(value);

          // Si solo hay un dígito y no es vacío, avanzar al siguiente campo
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          // Si está vacío, retroceder al campo anterior
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
