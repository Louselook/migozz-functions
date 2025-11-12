// recording_display.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class RecordingDisplay extends StatelessWidget {
  final Duration duration;
  // ❌ Ya no necesitas waveController aquí

  const RecordingDisplay({
    super.key,
    required this.duration,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 🔴 Indicador de grabación (pulsante)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // ⏱️ Duración
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 📊 Barras animadas simples (sin waveform real)
          Expanded(
            child: _AnimatedBars(),
          ),
        ],
      ),
    );
  }
}

// Widget simple de barras animadas
class _AnimatedBars extends StatefulWidget {
  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(20, (i) {
            final phase = (i / 20) * 2 * 3.14159;
            final height = 4 + (_controller.value * 16) * 
                          (0.5 + 0.5 * (1 + sin(phase / 3.14159)) / 2);
            return Container(
              width: 2,
              height: height,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}