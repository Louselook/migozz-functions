import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/audio_utils.dart';

class AudioPlayerDisplay extends StatelessWidget {
  final PlayerController playerController;
  final Duration duration;
  final Duration maxDuration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final void Function(Duration) onSeek;

  const AudioPlayerDisplay({
    super.key,
    required this.playerController,
    required this.duration,
    required this.maxDuration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
  });

  double _dxToProgress(double dx, double width) {
    if (maxDuration.inMilliseconds <= 0) return 0.0;
    return (dx.clamp(0.0, width) / width) * maxDuration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textInputBackGround,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPlayPause,
            icon: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final pos = Duration(
                      milliseconds: _dxToProgress(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      ).round(),
                    );
                    onSeek(pos);
                  },
                  onHorizontalDragUpdate: (details) {
                    final dx = details.localPosition.dx;
                    final pos = Duration(
                      milliseconds: _dxToProgress(
                        dx,
                        constraints.maxWidth,
                      ).round(),
                    );
                    onSeek(pos);
                  },
                  child: AudioFileWaveforms(
                    playerController: playerController,
                    size: Size(constraints.maxWidth, 20),
                    enableSeekGesture: false,
                    waveformType: WaveformType.fitWidth,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              "${AudioUtils.formatDuration(duration)} / ${AudioUtils.formatDuration(maxDuration)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
