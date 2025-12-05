import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

// Texto principal
class PrimaryText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const PrimaryText(this.text, {this.color, this.textAlign, super.key, maxLines, TextOverflow? overflow});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      style: TextStyle(
        fontSize: 24, // tamaño fijo H2
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.backgroundLight, // color por defecto blanco
      ),
    );
  }
}

// Texto Secundario
class SecondaryText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final double? fontSize;
  final FontWeight? fontWeight;

  const SecondaryText(
    this.text, {
    this.color,
    this.textAlign,
    this.fontSize = 12,
    this.fontWeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      style: TextStyle(
        fontSize: fontSize, // tamaño fijo H2
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.secondaryText, // color por defecto blanco
      ),
    );
  }
}

class TextWithIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool iconAtEnd;
  final double spacing;

  const TextWithIcon(
    this.text, {
    required this.icon,
    this.iconAtEnd = true,
    this.spacing = 6.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.backgroundLight,
      ),
    );

    final iconWidget = Icon(icon, size: 18, color: AppColors.backgroundLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAtEnd
          ? [textWidget, SizedBox(width: spacing), iconWidget]
          : [iconWidget, SizedBox(width: spacing), textWidget],
    );
  }
}

class ButtonText extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  const ButtonText({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.textLight,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

TextSpan gradientTextSpan(String text, {VoidCallback? onTap}) {
  return TextSpan(
    text: text,
    style: TextStyle(
      fontSize: 13,
      foreground: Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF28A57), Color(0xFF6C1D5E)],
          stops: [0.2, 1],
        ).createShader(const Rect.fromLTWH(90, 0, 200, 70)),
    ),
    recognizer: onTap != null ? (TapGestureRecognizer()..onTap = onTap) : null,
  );
}
