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
  final VoidCallback? onDelete; // 👈 Nuevo: callback para eliminar
  final void Function(Duration) onSeek;

  const AudioPlayerDisplay({
    super.key,
    required this.playerController,
    required this.duration,
    required this.maxDuration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
    this.onDelete, // 👈 Opcional
  });

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
          // 🎵 Botón de play/pause (circular con gradiente)
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFDF48A5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 🌊 Waveform completa (diseño horizontal)
          Expanded(
            child: SizedBox(
              height: 24,
              child: AudioFileWaveforms(
                playerController: playerController,
                waveformType: WaveformType.fitWidth,
                size: const Size(double.infinity, 24),
                enableSeekGesture: false, // Deshabilitado para simplicidad
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: const Color(0xFF555555),
                  liveWaveGradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.primaryGradient.colors,
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 24)),
                  waveThickness: 1.2,
                  spacing: 1.8,
                  showBottom: true,
                  showTop: true,
                  scaleFactor: 150.0,
                  waveCap: StrokeCap.round,
                  showSeekLine: false,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ⏱️ Tiempo actual
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AudioUtils.formatDuration(duration),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          // 🗑️ Botón de eliminar (si existe callback)
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
