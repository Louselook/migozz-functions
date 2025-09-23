import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/profile/pages/profile_screen.dart';

enum UserDetailsAction { next, finalRegister, back }

Widget userDetailsButton({
  required PageController controller,
  required BuildContext context,
  UserDetailsAction action = UserDetailsAction.back,
}) {
  return GradientButton(
    width: double.infinity,
    radius: 19,
    onPressed: () {
      switch (action) {
        case UserDetailsAction.next:
          controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          break;

        case UserDetailsAction.finalRegister:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
            (route) => false,
          );
          break;

        case UserDetailsAction.back:
          Navigator.pop(context, 'done');
          break;
      }
    },
    child: const SecondaryText('Continue', fontSize: 20),
  );
}
