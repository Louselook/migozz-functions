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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly || onTap != null, // evita que se edite manualmente
        onTap: onTap, // ejecuta el callback si se pasa
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          // si es un campo especial, mostramos el valor ya formateado
          suffixText: displayValue,
          suffixStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}


