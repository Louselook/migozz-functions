import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget googleButton({required VoidCallback onPressed, String text = 'Google'}) {
  return Container(
    width: 163,
    height: 41,
    decoration: BoxDecoration(
      color: AppColors.backgroundGoole,
      borderRadius: BorderRadius.circular(19),
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      icon: SvgPicture.asset(
        'assets/icons/Google.svg',
        width: 24,
        height: 24,
        semanticsLabel: 'Google',
        placeholderBuilder: (context) =>
            const Icon(Icons.g_mobiledata, color: AppColors.textLight),
      ),
      label: SecondaryText(text, color: AppColors.grey),
    ),
  );
}
