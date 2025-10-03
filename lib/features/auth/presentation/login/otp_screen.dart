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
    return BlocListener<LoginCubit, 
    LoginState>(
      listener: (context, state) {
        if (state.errorMessageOTP != null) {
          // Limpiar error en el cubit para que no se repita
          context.read<LoginCubit>().clearError();
          CustomSnackbar.show(
            context: context,
            message: state.errorMessageOTP!,
            type: SnackbarType.error,
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
              child: Column(
                children: [
                  _titleSection(email: widget.email),
                  const SizedBox(height: 40),
                  _OtpFields(
                    controllers: _controllers,
                    onCompleted: (otp) {
                      context.read<LoginCubit>().validateOTPAndLogin(
                      inputOTP: otp);
                      // Ahora se maneja con el botón
                    }
                  ),
                  _ResendButton(email: widget.email, otp: widget.userOTP),
                  const Spacer(),
                  // Imagen en el medio
                  const _ImageSection(),
                ],
              ),
            ),
          ),
      )
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

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Caso PASTE (más de un dígito pegado)
      // 1. Limpiar todo antes de repartir
      for (int i = 0; i < widget.controllers.length; i++) {
        widget.controllers[i].clear();
      }

      // 2. Repartir caracteres en los campos
      List<String> chars = value.split('');
      for (int i = 0; i < chars.length; i++) {
        if (i < widget.controllers.length) {
          widget.controllers[i].text = chars[i];
        }
      }

      // 3. Posicionar foco al último caracter pegado
      int lastIndex = (chars.length - 1).clamp(0, 5);
      _focusNodes[lastIndex].requestFocus();
    } else {
      // Caso normal (tecleo o borrar)
      if (value.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else if (value.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Construir OTP
    String otp = widget.controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      widget.onCompleted(otp);
    }
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
            autofocus: index == 0, // auto-focus en el primer campo
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
        // context.read<LoginCubit>().sendOTP(email);
        debugPrint('estado correo: $email, otp: $otp');
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
    return Column(
      children: [
        const Image(
          image:AssetImage('assets/images/otp_image.png'),
          width: 300,
          ),
      ],
    );
  }
}
