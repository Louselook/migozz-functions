// Mock de audio_waveforms para web
import 'package:flutter/material.dart';

class PlayerController {
  int maxDuration = 0;
  
  PlayerController();
  
  Future<void> preparePlayer({
    String? path,
    bool? shouldExtractWaveform,
    int? noOfSamples,
  }) async {
    // No-op en web
  }
  
  Future<void> startPlayer() async {}
  Future<void> pausePlayer() async {}
  void seekTo(int milliseconds) {}
  void dispose() {}
}

enum WaveformType { fitWidth, long }

class PlayerWaveStyle {
  final Color fixedWaveColor;
  final Color liveWaveColor;
  final Color seekLineColor;
  final double seekLineThickness;
  final bool showSeekLine;
  final double waveThickness;
  final double spacing;
  final bool showBottom;
  final bool showTop;
  final double scaleFactor;
  final StrokeCap waveCap;

  const PlayerWaveStyle({
    required this.fixedWaveColor,
    required this.liveWaveColor,
    required this.seekLineColor,
    required this.seekLineThickness,
    required this.showSeekLine,
    required this.waveThickness,
    required this.spacing,
    required this.showBottom,
    required this.showTop,
    required this.scaleFactor,
    required this.waveCap,
  });
}

// Widget mock para web
class AudioFileWaveforms extends StatelessWidget {
  final PlayerController playerController;
  final WaveformType waveformType;
  final Size size;
  final bool enableSeekGesture;
  final PlayerWaveStyle playerWaveStyle;

  const AudioFileWaveforms({
    super.key,
    required this.playerController,
    required this.waveformType,
    required this.size,
    required this.enableSeekGesture,
    required this.playerWaveStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Retorna un placeholder visual para web
    return Container();
  }
}