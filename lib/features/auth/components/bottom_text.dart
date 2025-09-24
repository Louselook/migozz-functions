import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

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
            context.go('/register');
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
