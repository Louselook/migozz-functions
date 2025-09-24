import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/email_otp_custom.dart';

class NewOtpTest extends StatefulWidget {
  const NewOtpTest({super.key});

  @override
  State<NewOtpTest> createState() => _NewOtpTestState();
}

class _NewOtpTestState extends State<NewOtpTest> {
  // final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> sendOTP() async {
    // juancitomarimoto@gmail.com
    bool sent = await EmailOTP.sendOTP(email: 'juancitomarimoto@gmail.com');

    if (sent) {
      debugPrint("OTP generado: ${EmailOTP.getOTP()}");
    } else {
      debugPrint("❌ Error al enviar OTP");
    }
  }

  Future<void> verifyOtp() async {
    // final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    // if (email.isEmpty || otp.isEmpty) {
    //   debugPrint("❌ Email u OTP vacíos");
    //   return;
    // }

    // Verifica que el OTP ingresado sea correcto
    bool isValid = EmailOTP.verifyOTP(otp: otp);

    if (isValid) {
      debugPrint("✅ OTP verificado correctamente");
      // Aquí puedes continuar con el flujo, ej: login o registro
    } else {
      debugPrint("❌ OTP incorrecto");
      // Mostrar error en la UI, alert, snackbar, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                // controller: _emailController,
                hintText: 'Correo electrónico',
                prefixIcon: const Icon(
                  Icons.email,
                  color: AppColors.secondaryText,
                ),
                suffixIcon: IconButton(
                  onPressed: sendOTP,
                  icon: const Icon(Icons.send_time_extension_outlined),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _otpController,
                hintText: 'OTP',
                prefixIcon: const Icon(
                  Icons.lock,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: verifyOtp,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Verify OTP', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
