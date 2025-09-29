import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:migozz_app/core/color.dart';
import 'audio_utils.dart';

class RecordingDisplay extends StatelessWidget {
  final Duration duration;
  final RecorderController waveController;

  const RecordingDisplay({
    super.key,
    required this.duration,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textInputBackGround,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(Icons.mic, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AudioWaveforms(
              size: const Size(double.infinity, 40),
              recorderController: waveController,
              enableGesture: false,
              waveStyle: WaveStyle(
                waveColor: AppColors.primaryGradient.colors.last,
                extendWaveform: true,
                showMiddleLine: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AudioUtils.formatDuration(duration),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
