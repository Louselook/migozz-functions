import 'package:flutter/material.dart';

/// Campo de búsqueda personalizado con estilo
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final double borderRadius;
  final double prefixIconSize;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.borderRadius,
    required this.prefixIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      autofocus: false,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: prefixIconSize,
          color: Colors.white.withOpacity(0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        isDense: true,
      ),
    );
  }
}
