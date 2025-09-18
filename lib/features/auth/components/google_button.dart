import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

Widget googleButton() {
  return Container(
    width: 163,
    height: 41,
    decoration: BoxDecoration(
      color: AppColors.backgroundGoole,
      borderRadius: BorderRadius.circular(19),
    ),
    child: ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      icon: Image.asset(
        'assets/icons/google_icon.png',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.g_mobiledata, color: AppColors.textLight);
        },
      ),
      label: const SecondaryText('Google', color: AppColors.grey),
    ),
  );
}
