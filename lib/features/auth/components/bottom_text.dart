import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget bottomText({required BuildContext context}) {
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: const TextStyle(fontSize: 13, color: Colors.grey),
      children: [
        TextSpan(text: "login.presentation.bottonText.Register".tr()),
        gradientTextSpan(
          "login.presentation.bottonText.RegisterSpan".tr(),
          onTap: () {
            context.go('/register');
          },
        ),
        TextSpan(text: "login.presentation.bottonText.Terms&Conditions".tr()),
        gradientTextSpan(
          "login.presentation.bottonText.Terms&ConditionsSpan".tr(),
          onTap: () {
            context.go('/terms-privacy');
          },
        ),
      ],
    ),
  );
}
