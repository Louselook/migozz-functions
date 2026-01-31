import 'package:flutter/material.dart';

class TransactionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final List<Color> colors;

  const TransactionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return (Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ).createShader(bounds);
            },
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 5),
          // TEXTO
          Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ));
  }
}
