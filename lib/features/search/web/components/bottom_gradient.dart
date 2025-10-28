import 'package:flutter/material.dart';

/// Gradiente inferior decorativo
class BottomGradient extends StatelessWidget {
  final double height;

  const BottomGradient({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF722583).withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
