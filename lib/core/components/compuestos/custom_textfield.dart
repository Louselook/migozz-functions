import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String hintText;
  final bool obscureText;
  final double radius;
  final TextInputType keyboardType;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int minLines;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final Color? cursorColor;

  const CustomTextField({
    super.key,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText = "Enter text",
    this.obscureText = false,
    this.radius = 19,
    required this.keyboardType,
    this.onSubmitted,
    this.textInputAction = TextInputAction.newline,
    this.maxLines = 1,
    this.minLines = 1,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.enabledBorder,
    this.focusedBorder,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 50,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.textInputBackGround,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TextField(
        controller: controller,
        cursorColor: cursorColor ?? textColor ?? AppColors.secondaryText,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        maxLines: maxLines,
        minLines: minLines,
        style: TextStyle(
          color: textColor ?? AppColors.secondaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor ?? AppColors.secondaryText,
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
          enabledBorder:
              enabledBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
          focusedBorder:
              focusedBorder ??
              OutlineInputBorder(
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
