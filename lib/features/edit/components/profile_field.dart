import 'package:flutter/material.dart';

class ProfileField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? displayValue;

  const ProfileField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.displayValue,
  });

    @override
  Widget build(BuildContext context) {
    final showValue = displayValue != null && (controller == null || controller!.text.isEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        
        controller: controller,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(0, 12, 0, 0),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white),
          // si hay displayValue lo mostramos como hint (izquierda); si no, usamos hint normal
          hintText: showValue ? displayValue : hint,
          hintStyle: const TextStyle(color: Colors.white70),
          // no usar suffixText para evitar duplicados
        ),
      ),
    );
  }
}


