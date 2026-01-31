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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.backgroundDark,
            ),
            onPressed: () {
              context.read<LoginCubit>().resetState();
              context.pop();
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isLarge = constraints.maxWidth >= 768;
              final bool isCompact = constraints.maxWidth < 360;
              final double contentWidth = isLarge
                  ? 560
                  : (constraints.maxWidth * 0.9).clamp(280.0, 520.0);
              final double spacing = isLarge ? 16 : (isCompact ? 8 : 12);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const PrimaryText(
                        'Enter OTP Code',
                        color: AppColors.backgroundDark,
                      ),
                      const SizedBox(height: 8),
                      SecondaryText(
                        'OTP code has been sent to ${widget.email}',
                        color: AppColors.greyBackground,
                        fontSize: 13,
                      ),
                      const SizedBox(height: 40),

                      // OTP fields + resend
                      LayoutBuilder(
                        builder: (context, rowCx) {
                          final double minBox = 44;
                          final double maxBox = 70;
                          final resendReserve = isLarge ? 84.0 : 72.0;
                          final available = rowCx.maxWidth - resendReserve;
                          final computed = ((available - spacing * 5) / 6)
                              .clamp(minBox, maxBox);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: (computed * 6) + (spacing * 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: List.generate(6, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: i < 5 ? spacing : 0,
                                      ),
                                      child: _OtpBoxField(
                                        size: computed,
                                        controller: _controllers[i],
                                        focusNode: i == 0
                                            ? _firstFocusNode
                                            : null,
                                        isFirst: i == 0,
                                        index: i,
                                        onChanged: (v) {
                                          setState(
                                            () {},
                                          ); // Actualizar botón "Verify"
                                          if (v.length > 1) {
                                            // Handle paste
                                            final digits = v
                                                .replaceAll(
                                                  RegExp(r'[^0-9]'),
                                                  '',
                                                )
                                                .split('');
                                            for (
                                              int j = 0;
                                              j < digits.length && j < 6;
                                              j++
                                            ) {
                                              _controllers[j].text = digits[j];
                                            }
                                            if (digits.length >= 6) {
                                              // Focus reset or dismiss logic could go here
                                              FocusScope.of(context).unfocus();
                                              _handleOtpCompletion(
                                                _controllers
                                                    .map((c) => c.text)
                                                    .join(),
                                              );
                                            }
                                          } else {
                                            // Normal single digit entry
                                            final code = _controllers
                                                .map((c) => c.text)
                                                .join();
                                            if (code.length == 6) {
                                              FocusScope.of(context).unfocus();
                                              _handleOtpCompletion(code);
                                            }
                                          }
                                        },
                                        onSubmitted: (_) {
                                          final code = _controllers
                                              .map((c) => c.text)
                                              .join();
                                          if (code.length == 6) {
                                            _handleOtpCompletion(code);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              const SizedBox(width: 16),

                              SizedBox(
                                width: resendReserve - 16,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () => context
                                        .read<LoginCubit>()
                                        .sendOTPLoginCubit(
                                          widget.email,
                                          language: context.locale.languageCode,
                                        ),
                                    child: const SecondaryText(
                                      'Resend',
                                      color: AppColors.greyBackground,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      Align(
                        child: Image.asset(
                          'assets/images/otp_image.webp',
                          width: isLarge ? 300 : (isCompact ? 200 : 240),
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 28),

                      Align(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isLarge ? 420 : 380,
                            minWidth: 220,
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _controllers.map((c) => c.text).join().length ==
                                    6
                                ? () => _handleOtpCompletion(
                                    _controllers.map((c) => c.text).join(),
                                  )
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isLarge ? 18 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor:
                                  AppColors.primaryGradient.colors.first,
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OtpBoxField extends StatelessWidget {
  final double size;
  final TextEditingController controller;
  final int index;
  final bool isFirst;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted; // New parameter

  const _OtpBoxField({
    required this.size,
    required this.controller,
    required this.index,
    required this.isFirst,
    this.focusNode,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: isFirst, // primer campo enfocado automáticamente
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        showCursor: false,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC5CAD3), width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9321BD), width: 1.6),
          ),
        ),
        onChanged: (value) {
          // Si escribió un dígito, pasa al siguiente campo
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }

          // Si borró (quedó vacío) y no es el primero, vuelve al anterior
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }

          // Notificamos al padre para que arme el OTP, valide, etc.
          onChanged(value);
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
