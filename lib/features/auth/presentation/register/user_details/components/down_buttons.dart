import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/custom_button.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget downButtons({required PageController controller}) {
  return Column(
    children: [
      GradientButton(
        width: double.infinity,
        radius: 19,
        onPressed: () => controller.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ),
        child: const SecondaryText('Continue', fontSize: 20),
      ),
      const SizedBox(height: 15),
      CustomButton(
        width: double.infinity,
        radius: 19,
        onPressed: () => controller.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ),
        child: const SecondaryText('Skip this step', fontSize: 20),
      ),
    ],
  );
}
