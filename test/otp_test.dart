import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';

class OtpTest extends StatefulWidget {
  const OtpTest({super.key});

  @override
  State<OtpTest> createState() => _OtpTestState();
}

class _OtpTestState extends State<OtpTest> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final String apiUrl = "http://10.0.2.2:8000";
  Future<void> sendOTP() async {
    final email = _emailController.text;
    final url = Uri.parse("$apiUrl/send-otp/$email");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      debugPrint("OTP enviado ✅");
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP enviado al correo")));
    } else {
      debugPrint("Error enviando OTP ❌: ${response.body}");
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Error enviando OTP")));
    }
  }

  Future<void> verifyOtp() async {
    final email = _emailController.text;
    final otp = _otpController.text;
    final url = Uri.parse("$apiUrl/verify-otp/$email/$otp");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      debugPrint("OTP Verified ✅");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP válido ✅")));
    } else {
      debugPrint("Invalid OTP ❌: ${response.body}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP inválido ❌")));
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
                controller: _emailController,
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
