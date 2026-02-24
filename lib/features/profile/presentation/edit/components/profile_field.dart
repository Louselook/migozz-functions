import 'package:flutter/material.dart';

class ProfileField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? displayValue;
  final IconData? trailingIcon;
  final int maxLines;

  const ProfileField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.displayValue,
    this.trailingIcon,
    this.maxLines = 1,
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
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly || onTap != null,
              onTap: onTap,
              maxLines: maxLines,
              cursorColor: Colors.white,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                ),
                suffixIcon: effectiveTrailingIcon != null
                    ? Icon(
                        effectiveTrailingIcon,
                        color: Colors.white.withValues(alpha: 0.4),
                      )
                    : null,
                // si hay displayValue lo mostramos como hint (izquierda); si no, usamos hint normal
                hintText: showValue ? displayValue : hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                // no usar suffixText para evitar duplicados
              ),
            ),
          ],
        ),
      ),
    );
  }
}
