// recording_display.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class RecordingDisplay extends StatelessWidget {
  final Duration duration;
  final double amplitude;

  const RecordingDisplay({
    super.key,
    required this.duration,
    this.amplitude = 0.0,
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
          //  Indicador de grabación (pulsante)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Duración
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Barras que responden a amplitud real del micrófono
          Expanded(
            child: _AmplitudeVisualizer(amplitude: amplitude),
          ),
        ],
      ),
    );
  }
}

class _AmplitudeVisualizer extends StatefulWidget {
  final double amplitude; // 0.0 a 1.0

  const _AmplitudeVisualizer({required this.amplitude});

  @override
  State<_AmplitudeVisualizer> createState() => _AmplitudeVisualizerState();
}

class _AmplitudeVisualizerState extends State<_AmplitudeVisualizer> {
  static const int _barCount = 18;
  static const double _baseHeight = 4.0;
  static const double _maxExtraHeight = 18.0;
  static const double _silentThreshold = 0.06;

  final List<double> _shape = List<double>.filled(_barCount, 0.0);
  Timer? _timer;
  int _tick = 0;

  bool get _isSilent => widget.amplitude <= _silentThreshold;

  @override
  void initState() {
    super.initState();
    _setSilentShape();
  }

  @override
  void didUpdateWidget(covariant _AmplitudeVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop animation depending on voice presence.
    if (_isSilent) {
      _stop();
      _setSilentShape();
    } else {
      _start();
    }
  }

  void _setSilentShape() {
    // Stable low bars (no animation) when not speaking.
    for (var i = 0; i < _barCount; i++) {
      _shape[i] = 0.0;
    }
    if (mounted) setState(() {});
  }

  void _start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      if (_isSilent) return;

      // Generate a moving wave-like pattern.
      _tick++;
      for (var i = 0; i < _barCount; i++) {
        final phase = (i / _barCount) * 2 * pi;
        final motion = sin(phase + (_tick * 0.35));
        final jitter = sin((phase * 3) + (_tick * 0.22));
        final v = ((motion + 1) / 2) * 0.75 + ((jitter + 1) / 2) * 0.25;
        _shape[i] = v.clamp(0.0, 1.0);
      }
      setState(() {});
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amp = widget.amplitude.clamp(0.0, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_barCount, (i) {
        final extra = amp * _maxExtraHeight * _shape[i];
        final height = _baseHeight + extra;

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
  }
}