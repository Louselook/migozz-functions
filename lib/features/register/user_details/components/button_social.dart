import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget newButtonBack({
  required PageController controller,
  required BuildContext context,
}) {
  return Column(
    children: [
      GradientButton(
        width: double.infinity,
        radius: 19,
        onPressed: () {
          Navigator.pop(context, "done");
        },
        child: const SecondaryText('Continue', fontSize: 20),
      ),
    ],
  );
}
