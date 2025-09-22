import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/register/register_screen.dart';
import 'package:migozz_app/features/auth/presentation/register/test.dart';

Widget bottomText({required BuildContext context}) {
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: const TextStyle(fontSize: 13, color: Colors.grey),
      children: [
        const TextSpan(text: "Don't have an account? "),
        gradientTextSpan(
          "Register Now\n",
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterScreenTest(),
              ),
            );
          },
        ),
        const TextSpan(text: " By registering you agree to our\n"),
        gradientTextSpan(
          "Terms and conditions",
          onTap: () {
            debugPrint("Términos y condiciones presionados");
          },
        ),
      ],
    ),
  );
}
