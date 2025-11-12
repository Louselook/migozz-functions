import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_input/audio_utils.dart';

class AudioPlayerDisplay extends StatelessWidget {
  final PlayerController playerController;
  final Duration duration;
  final Duration maxDuration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onDelete;
  final void Function(Duration) onSeek;

  const AudioPlayerDisplay({
    super.key,
    required this.playerController,
    required this.duration,
    required this.maxDuration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Usar maxDuration del parámetro (viene de just_audio)
    Duration effectiveMaxDuration = maxDuration;

    // ✅ Solo como fallback usar playerController
    if (effectiveMaxDuration == Duration.zero &&
        playerController.maxDuration > 0) {
      effectiveMaxDuration = Duration(
        milliseconds: playerController.maxDuration,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textInputBackGround,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Botón play/pause
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

              // Waveform interactiva (SOLO visual - no reproduce audio)
              Expanded(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (effectiveMaxDuration == Duration.zero) return;

                    final RenderBox? box =
                        context.findRenderObject() as RenderBox?;
                    if (box == null) return;

                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    final width = box.size.width;
                    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
                    final newPosition = Duration(
                      milliseconds:
                          (effectiveMaxDuration.inMilliseconds * ratio).round(),
                    );
                    onSeek(newPosition);
                  },
                  onTapDown: (details) {
                    if (effectiveMaxDuration == Duration.zero) return;

                    final RenderBox? box =
                        context.findRenderObject() as RenderBox?;
                    if (box == null) return;

                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    final width = box.size.width;
                    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
                    final newPosition = Duration(
                      milliseconds:
                          (effectiveMaxDuration.inMilliseconds * ratio).round(),
                    );
                    onSeek(newPosition);
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: 36,
                    child: AudioFileWaveforms(
                      playerController: playerController,
                      waveformType: WaveformType.fitWidth,
                      size: const Size(double.infinity, 36),
                      enableSeekGesture:
                          false, // ✅ Deshabilitado para evitar conflictos
                      playerWaveStyle: PlayerWaveStyle(
                        fixedWaveColor: const Color(0xFF555555),
                        liveWaveColor: const Color(0xFFDF48A5),
                        seekLineColor: Colors.white,
                        seekLineThickness: 2,
                        showSeekLine: true,
                        waveThickness: 1.8,
                        spacing: 2.5,
                        showBottom: true,
                        showTop: true,
                        scaleFactor: 150.0,
                        waveCap: StrokeCap.round,
                      ),
                    ),
                  ),
                ),
              ),

              // Botón de eliminar
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

          const SizedBox(height: 6),

          // ⏱️ Tiempo en esquina inferior derecha
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  effectiveMaxDuration > Duration.zero
                      ? '${AudioUtils.formatDuration(duration)}/${AudioUtils.formatDuration(effectiveMaxDuration)}'
                      : '0:00/${AudioUtils.formatDuration(duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
