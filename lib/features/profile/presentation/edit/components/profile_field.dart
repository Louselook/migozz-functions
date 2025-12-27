import 'package:flutter/material.dart';

class ProfileField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? displayValue;
  final IconData? trailingIcon;

  const ProfileField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.displayValue,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final showValue =
        displayValue != null &&
        (controller == null || controller!.text.isEmpty);
    final effectiveTrailingIcon =
        trailingIcon ?? (onTap != null ? Icons.chevron_right : null);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        cursorColor: Colors.white,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: InputBorder.none,
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          suffixIcon: effectiveTrailingIcon != null
              ? Icon(
                  effectiveTrailingIcon,
                  color: Colors.white.withValues(alpha: 0.4),
                )
              : null,
          // si hay displayValue lo mostramos como hint (izquierda); si no, usamos hint normal
          hintText: showValue ? displayValue : hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          // no usar suffixText para evitar duplicados
        ),
      ),
    );
  }
}
