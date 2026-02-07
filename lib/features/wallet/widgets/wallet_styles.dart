import 'package:flutter/material.dart';

class WalletBoxStyles {
  final containerBackground = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color.fromARGB(59, 255, 255, 255)),
  );

  final inputBackgroud = BoxDecoration(
    color: const Color.fromARGB(19, 255, 255, 255),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color.fromARGB(52, 255, 255, 255)),
  );
}



class GradientText extends StatelessWidget {
  final String text;
  final double size;

  const GradientText({super.key, required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFF9022BA), Color(0xFFDC44AA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Colors
              .white, // El color base debe ser blanco para que el degradado brille
        ),
      ),
    );
  }
}
