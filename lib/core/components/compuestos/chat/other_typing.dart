import 'package:flutter/material.dart';

class OtherTyping extends StatefulWidget {
  final String name; // Nombre dinámico que aparecerá antes de los puntos

  const OtherTyping({super.key, required this.name});

  @override
  State<OtherTyping> createState() => _OtherTypingState();
}

class _OtherTypingState extends State<OtherTyping>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = (_controller.value + i * 0.2) % 1.0;
                return Transform.translate(
                  offset: Offset(0, -5 * (0.5 - (value - 0.5).abs())),
                  child: child,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.5),
                child: Dot(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}
