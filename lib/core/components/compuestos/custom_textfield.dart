import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final Icon? prefixIcon;
  final IconButton? suffixIcon;
  final String hintText;
  final bool obscureText;
  final double radius;

  const CustomTextField({
    super.key,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText = "Enter text",
    this.obscureText = false,
    this.radius = 19,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.textInputBackGround,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.secondaryText,
        obscureText: obscureText,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: prefixIcon,
                )
              : null,
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            // borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(
              color: AppColors.primaryPink,
              width: .5,
            ),
          ),
        ),
      ),
    );
  }
}
