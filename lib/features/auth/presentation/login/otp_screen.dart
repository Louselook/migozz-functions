import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
// import 'package:migozz_app/pruebas/otp_validator.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';

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

  void validateOTP({required String otp}) {
    if (widget.userOTP == otp) {
      CustomSnackbar.show(
        context: context,
        message: "OTP correcto",
        type: SnackbarType.success,
      );
      // changePassword(email: widget.email, newPassword: otp);
    } else {
      debugPrint('user:$otp server: ${widget.userOTP}');
      CustomSnackbar.show(
        context: context,
        message: "OTP incorrecto",
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            children: [
              _titleSection(email: widget.email),
              const SizedBox(height: 40),
              _OtpFields(
                controllers: _controllers,
                onCompleted: (otp) => validateOTP(otp: otp),
              ),
              const _ResendButton(),
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
  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.controllers.length; i++) {
      widget.controllers[i].addListener(() => _onChange(i));
    }
  }

  void _onChange(int index) {
    if (widget.controllers[index].text.length == 1 && index < 5) {
      FocusScope.of(context).nextFocus();
    } else if (widget.controllers[index].text.isEmpty && index > 0) {
      FocusScope.of(context).previousFocus();
    }

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
  const _ResendButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        debugPrint("Reenviar código");
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
