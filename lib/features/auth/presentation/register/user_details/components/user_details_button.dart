import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          context.go('/profile');
          break;

        case UserDetailsAction.back:
          context.pop('done');
          break;
      }
    },
    child: const SecondaryText('Continue', fontSize: 20),
  );
}
