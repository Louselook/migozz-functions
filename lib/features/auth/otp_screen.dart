import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    for (var controller in _controllers) {
      controller.addListener(_validateCode);
    }
  }

  void _validateCode() {
    String code = _controllers.map((c) => c.text).join();

    if (code.contains('') && code.length < 6) {
      debugPrint("el codigo esta vacio");
    }

    if (code.length == 6 && !_controllers.any((c) => c.text.isEmpty)) {
      debugPrint("datos completos: $code");
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              _titleSection(email: 'correo@gmail.com'),
              const SizedBox(height: 40),
              _OtpFields(controllers: _controllers),
              const _ResendButton(),
              const Spacer(),
              const _ImageSection(),
              const SizedBox(height: 40),

              // button
              GradientButton(
                width: double.infinity,
                radius: 19,
                height: 50,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OtpScreen()),
                  );
                },
                child: const SecondaryText('Verify', fontSize: 20),
              ),
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

class _OtpFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  const _OtpFields({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          color: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 44,
          height: 44,
          child: TextField(
            controller: controllers[index],
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
