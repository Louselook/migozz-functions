import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

enum UserDetailsAction { next, finalRegister, back }

Widget userDetailsButton({
  required PageController controller,
  required BuildContext context,
  UserDetailsAction action = UserDetailsAction.back,
  Future<void> Function()? onFinalAction,
}) {
  return GradientButton(
    width: double.infinity,
    radius: 19,
    onPressed: () async {
      switch (action) {
        case UserDetailsAction.next:
          controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          break;

        case UserDetailsAction.finalRegister:
          if (onFinalAction != null) {
            await onFinalAction();
          }
          break;

        case UserDetailsAction.back:
          context.pop('done');
          break;
      }
    },
    child: const SecondaryText('Continue', fontSize: 20),
  );
}
