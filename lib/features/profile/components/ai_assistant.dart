// lib/features/profile/components/ai_assistant.dart
import 'package:flutter/material.dart';

class AIAssistant extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AIAssistant({super.key, this.size = 30, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 2),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB86BFF), Color(0xFFFF5F9A), Color(0xFFF3C623)],
            ),
          ),
          child: Image.asset(
            'assets/icons/Assistans_Icon.png', // ojo al nombre exacto
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
