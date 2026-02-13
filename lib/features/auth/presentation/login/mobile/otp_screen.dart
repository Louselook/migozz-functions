import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';

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

  // Flags para evitar acciones repetidas
  final bool _hasNavigated = false;
  bool _isLoadingVisible = false;
  bool _hasProcessedAuth = false;

  // Key para acceder al estado de _OtpFields
  final GlobalKey<_OtpFieldsState> _otpFieldsKey = GlobalKey<_OtpFieldsState>();

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleOtpCompletion(String otp) async {
    // Evitar múltiples procesamientos
    if (_hasNavigated || _hasProcessedAuth) return;

    // 1. Primero validar OTP con LoginCubit (solo validación de UI)
    final loginCubit = context.read<LoginCubit>();
    final isValidOTP = await loginCubit.validateOTP(inputOTP: otp);

    if (!isValidOTP) {
      // Error ya mostrado por el listener de LoginCubit
      return;
    }

    // 2. OTP válido, ahora hacer autenticación real con AuthCubit
    _hasProcessedAuth = true;

    try {
      // ignore: use_build_context_synchronously
      context.read<AuthCubit>();

      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        context.read<LoginCubit>().setAuthenticationError(e.toString());
        _hasProcessedAuth = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener para LOADING del LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return previous.isLoading != current.isLoading;
          },
          listener: (context, state) {
            if (state.isLoading) {
              if (!_isLoadingVisible) {
                _isLoadingVisible = true;
                LoadingOverlay.show(context);
              }
            } else {
              if (_isLoadingVisible) {
                _isLoadingVisible = false;
                LoadingOverlay.hide(context);
              }
            }
          },
        ),

        // Listener para SUCCESS del LoginCubit (solo limpiar flag)
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return !previous.loginSuccess && current.loginSuccess;
          },
          listener: (context, state) {
            if (state.loginSuccess) {
              // Limpiar el flag en el cubit para evitar futuras dobles navegaciones
              context.read<LoginCubit>().clearLoginSuccess();
            }
          },
        ),

        // Listener para ERRORES OTP del LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return previous.otpErrorCount != current.otpErrorCount &&
                current.errorMessageOTP != null &&
                current.errorMessageOTP!.isNotEmpty;
          },
          listener: (context, state) {
            // Evitar apilar notificaciones
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // Mostrar snackbar con el error
            CustomSnackbar.show(
              context: context,
              message: state.errorMessageOTP!,
              type: SnackbarType.error,
            );

            // Borrar los campos de OTP y devolver foco al primero
            _otpFieldsKey.currentState?.clearAll();

            // Reset flag de procesamiento
            _hasProcessedAuth = false;
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Column(
              children: [
                _titleSection(email: widget.email),
                const SizedBox(height: 40),
                // Pasar la key al widget para poder limpiar desde el padre
                _OtpFields(
                  key: _otpFieldsKey,
                  controllers: _controllers,
                  onCompleted: _handleOtpCompletion,
                ),
                _ResendButton(email: widget.email, otp: widget.userOTP),
                const Spacer(),
                const _ImageSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====== Widgets auxiliares (sin cambios) ======

Widget _titleSection({required String email}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PrimaryText("login.otp.title".tr(), color: AppColors.backgroundDark),
      SecondaryText(
        "login.otp.subtitle".tr(namedArgs: {"email": email}),
        color: AppColors.greyBackground,
        fontSize: 13,
      ),
    ],
  );
}

class _OtpFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final void Function(String otp) onCompleted;
  const _OtpFields({
    super.key,
    required this.controllers,
    required this.onCompleted,
  });

  @override
  State<_OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<_OtpFields> {
  late List<FocusNode> _focusNodes;

  // Para detectar backspace en campo vacío
  late List<String> _previousValues;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
    _previousValues = List.generate(6, (_) => '');

    // Agregar listeners para detectar cambios
    for (int i = 0; i < 6; i++) {
      widget.controllers[i].addListener(() => _trackValue(i));
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _trackValue(int index) {
    // Actualizar valor previo para tracking
    _previousValues[index] = widget.controllers[index].text;
  }

  // Método público que puede invocar el padre vía GlobalKey
  void clearAll() {
    for (var c in widget.controllers) {
      c.clear();
    }
    _previousValues = List.generate(6, (_) => '');
    // forzamos que el primer campo tenga foco
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {});
  }

  /// Pegar código OTP completo
  void _handlePaste(String pastedText) {
    // Limpiar y filtrar solo dígitos
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return;

    // Limpiar todos los campos primero
    for (var c in widget.controllers) {
      c.clear();
    }

    // Distribuir cada dígito en su campo correspondiente
    for (int i = 0; i < digits.length && i < 6; i++) {
      widget.controllers[i].text = digits[i];
      _previousValues[i] = digits[i];
    }

    // Mover foco al siguiente campo vacío o al último si está completo
    final filledCount = digits.length.clamp(0, 6);
    if (filledCount >= 6) {
      _focusNodes[5].requestFocus();
      // Verificar si está completo
      _checkCompletion();
    } else {
      _focusNodes[filledCount.clamp(0, 5)].requestFocus();
    }

    setState(() {});
  }

  /// Verificar si el OTP está completo y llamar callback
  void _checkCompletion() {
    final otp = widget.controllers.map((c) => c.text).join();
    if (otp.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      widget.onCompleted(otp);
    }
  }

  void _onChanged(String value, int index) {
    // Detectar si es un paste (múltiples caracteres)
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    // Filtrar solo números
    if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
      widget.controllers[index].text = _previousValues[index];
      widget.controllers[index].selection = TextSelection.collapsed(
        offset: widget.controllers[index].text.length,
      );
      return;
    }

    // Si escribió un dígito
    if (value.isNotEmpty) {
      _previousValues[index] = value;

      // Mover al siguiente campo si no es el último
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }

      // Verificar si está completo
      _checkCompletion();
    }

    setState(() {});
  }

  /// Manejar tecla de retroceso (backspace)
  void _handleBackspace(int index) {
    final currentText = widget.controllers[index].text;

    if (currentText.isNotEmpty) {
      // Si hay texto, limpiarlo
      widget.controllers[index].clear();
      _previousValues[index] = '';
    } else if (index > 0) {
      // Si está vacío y no es el primero, ir al anterior y limpiarlo
      widget.controllers[index - 1].clear();
      _previousValues[index - 1] = '';
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  /// Manejar navegación con flechas
  void _handleArrowKey(int index, bool isLeft) {
    if (isLeft && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (!isLeft && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasValue = widget.controllers[index].text.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 48,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(), // Dummy focus node para KeyboardListener
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  _handleBackspace(index);
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _handleArrowKey(index, true);
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _handleArrowKey(index, false);
                }
              }
            },
            child: TextField(
              controller: widget.controllers[index],
              focusNode: _focusNodes[index],
              autofocus: index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  6,
                ), // Permitir paste de 6 dígitos
              ],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasValue
                        ? AppColors.primaryPurple
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryPurple,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: hasValue
                    ? AppColors.primaryPurple.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
              ),
              onChanged: (value) => _onChanged(value, index),
              onTap: () {
                // Seleccionar todo el texto al tocar para fácil reemplazo
                widget.controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: widget.controllers[index].text.length,
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _ResendButton extends StatelessWidget {
  final String email;
  final String otp;
  const _ResendButton({required this.email, required this.otp});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Reenvío de OTP
        context.read<LoginCubit>().sendOTPLoginCubit(
          email,
          language: context.locale.languageCode,
        );
      },
      child: SecondaryText(
        "login.otp.resend".tr(),
        color: AppColors.greyBackground,
        fontSize: 13,
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection();

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/images/otp_image.webp'),
      width: 300,
    );
  }
}
