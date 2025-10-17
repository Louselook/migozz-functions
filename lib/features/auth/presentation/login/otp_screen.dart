import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
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

  // 🔹 Flags para evitar acciones repetidas
  bool _hasNavigated = false;
  bool _isLoadingVisible = false;

  // 🔹 Key para acceder al estado de _OtpFields
  final GlobalKey<_OtpFieldsState> _otpFieldsKey = GlobalKey<_OtpFieldsState>();

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // 🔹 Listener para LOADING (igual que tenías)
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

        // 🔹 Listener para SUCCESS (sin manejar navegación aquí)
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) {
            return !previous.loginSuccess && current.loginSuccess;
          },
          listener: (context, state) {
            if (state.loginSuccess && !_hasNavigated) {
              _hasNavigated = true;
              // Limpiar el flag en el cubit para evitar futuras dobles navegaciones
              context.read<LoginCubit>().clearLoginSuccess();
            }
          },
        ),

        // 🔹 Listener para ERRORES OTP
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
                // 🔹 Pasar la key al widget para poder limpiar desde el padre
                _OtpFields(
                  key: _otpFieldsKey,
                  controllers: _controllers,
                  onCompleted: (otp) {
                    // Evitar múltiples llamadas si ya navegamos o si ya hay proceso en curso
                    if (!_hasNavigated) {
                      context.read<LoginCubit>().validateOTPAndLogin(
                        inputOTP: otp,
                      );
                    }
                  },
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

// ====== Widgets auxiliares ======

Widget _titleSection({required String email}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PrimaryText("Enter OTP Code", color: AppColors.backgroundDark),
      SecondaryText(
        "OTP code has been sent to $email",
        color: AppColors.backgroundGoole,
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

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Método público que puede invocar el padre vía GlobalKey
  void clearAll() {
    for (var c in widget.controllers) {
      c.clear();
    }
    // forzamos que el primer campo tenga foco
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {}); // actualizar UI por si acaso
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      for (var c in widget.controllers) {
        c.clear();
      }
      final chars = value.split('');
      for (int i = 0; i < chars.length && i < 6; i++) {
        widget.controllers[i].text = chars[i];
      }
      final nextIndex = (chars.length - 1).clamp(0, 5);
      _focusNodes[nextIndex].requestFocus();
    } else {
      if (value.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else if (value.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final otp = widget.controllers.map((c) => c.text).join();
    if (otp.length == 6) widget.onCompleted(otp);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 44,
          height: 44,
          child: TextField(
            controller: widget.controllers[index],
            focusNode: _focusNodes[index],
            autofocus: index == 0,
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(counterText: ""),
            onChanged: (value) => _onChanged(value, index),
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
        context.read<LoginCubit>().sendOTPLoginCubit(email);
      },
      child: const SecondaryText(
        "Resend",
        color: AppColors.backgroundGoole,
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
      image: AssetImage('assets/images/otp_image.png'),
      width: 300,
    );
  }
}
