import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget bottomText({required BuildContext context}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // "NEW USER? REGISTER HERE!"
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          children: [
            TextSpan(text: "login.presentation.bottomText.newUser".tr()),
            gradientTextSpanRegister(
              "login.presentation.bottomText.register".tr(),
              onTap: () {
                context.go('/register');
              },
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // "By registering you agree to our Terms and conditions"
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 2,
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              children: [
                TextSpan(text: "login.presentation.bottomText.agreement".tr()),
                gradientTextSpan(
                  "login.presentation.bottomText.terms".tr(),
                  onTap: () {
                    context.push('/terms-privacy');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
