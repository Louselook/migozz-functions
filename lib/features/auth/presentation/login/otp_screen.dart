import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String userOTP;
  const OtpScreen({super.key, required this.email, required this.userOTP});

  factory OtpScreen.fromExtra(BuildContext context) {
    final data = GoRouterState.of(context).extra as Map<String, dynamic>;
    return OtpScreen(email: data['email'], userOTP: data['userOTP']);
  }

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    // Ya no navegamos manualmente, GoRouter lo hará
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.errorMessageOTP != null) {
          // Limpiar error en el cubit para que no se repita
          CustomSnackbar.show(
            context: context,
            message: state.errorMessageOTP!,
            type: SnackbarType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.backgroundDark,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                _titleSection(email: widget.email),
                const SizedBox(height: 40),
                _OtpFields(
                  controllers: _controllers,
                  onCompleted: (otp) {
                    // ✅ Solo se manda el OTP
                    context.read<LoginCubit>().validateOTPAndLogin(
                      inputOTP: otp,
                    );
                  },
                ),
                _ResendButton(email: widget.email, otp: widget.userOTP),
                const Spacer(),
                const _ImageSection(),
                const SizedBox(height: 40),

                // botón comentado ya que el OTP se valida automáticamente
                // GradientButton(
                //   width: double.infinity,
                //   radius: 19,
                //   height: 50,
                //   onPressed: () => validateOTP(otp: _otpController.text),
                //   child: const SecondaryText('Verify', fontSize: 20),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====== Widgets separados ======

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
  const _OtpFields({required this.controllers, required this.onCompleted});

  @override
  State<_OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<_OtpFields> {
  final List<VoidCallback> _listeners = [];
  bool _hasSent = false; // Controla envío único

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.controllers.length; i++) {
      listener() => _onChange(i);
      _listeners.add(listener);
      widget.controllers[i].addListener(listener);
    }
  }

  @override
  void dispose() {
    for (var i = 0; i < widget.controllers.length; i++) {
      widget.controllers[i].removeListener(_listeners[i]);
    }
    super.dispose();
  }

  void _onChange(int index) {
    if (widget.controllers[index].text.length == 1 && index < 5) {
      FocusScope.of(context).nextFocus();
    } else if (widget.controllers[index].text.isEmpty && index > 0) {
      FocusScope.of(context).previousFocus();
    }

    String otp = widget.controllers.map((c) => c.text).join();
    if (otp.length == 6 && !_hasSent) {
      _hasSent = true; // ✅ evita que se envíe más de una vez
      widget.onCompleted(otp);
    }
  }

  // Método público para limpiar los campos y poder reintentar
  void clearFields() {
    for (var controller in widget.controllers) {
      controller.clear();
    }
    _hasSent = false; // Permitir enviar nuevamente
    FocusScope.of(context).requestFocus(FocusNode()); // Quitar foco
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double spacing = 8;
    int count = widget.controllers.length;
    double fieldWidth = (screenWidth - 60 - (count - 1) * spacing) / count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: fieldWidth.clamp(40, 60), // Limitar tamaño mínimo y máximo
          height: fieldWidth.clamp(40, 60),
          child: TextField(
            controller: widget.controllers[index],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(counterText: ""),
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
        // context.read<LoginCubit>().sendOTP(email);
        debugPrint('eestado correo: $email, otp: $otp');
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
    return const Icon(Icons.sms, size: 100, color: Colors.grey);
  }
}
