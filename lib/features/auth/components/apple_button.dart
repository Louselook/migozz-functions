import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget appleButton({required VoidCallback onPressed, String text = 'Apple'}) {
  return Container(


    decoration: BoxDecoration(
      color: AppColors.backgroundDark,
      border: Border.all(color: AppColors.grey.withValues(alpha: 0.3), width: 1),
      borderRadius: BorderRadius.circular(19),
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      icon: const Icon(
        Icons.apple,
        color: AppColors.textLight,
        size: 24,
      ),
      label: SecondaryText(text, color: AppColors.grey, fontSize: 15),

    ),
  );
}

