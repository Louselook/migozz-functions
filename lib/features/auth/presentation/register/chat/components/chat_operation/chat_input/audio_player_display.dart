import 'package:flutter/foundation.dart' show kIsWeb;


// ✅ Import condicional
import 'package:audio_waveforms/audio_waveforms.dart'
    if (dart.library.html) 'audio_waveforms_web.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/audio_utils.dart';

class AudioPlayerDisplay extends StatelessWidget {
  final dynamic playerController; // ✅ Cambiar a dynamic para soportar ambos
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
    Duration effectiveMaxDuration = maxDuration;

    // ✅ Fallback solo en móvil
    if (!kIsWeb &&
        effectiveMaxDuration == Duration.zero &&
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

              // ✅ Waveform condicional: real en móvil, fallback en web
              Expanded(
                child: kIsWeb
                    ? _buildWebAudioVisualizer(context, effectiveMaxDuration)
                    : _buildMobileWaveform(context, effectiveMaxDuration),
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

          // ⏱️ Tiempo
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

  // ✅ Waveform real para móvil
  Widget _buildMobileWaveform(BuildContext context, Duration effectiveMaxDuration) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _handleSeekGesture(context, details.globalPosition, effectiveMaxDuration);
      },
      onTapDown: (details) {
        _handleSeekGesture(context, details.globalPosition, effectiveMaxDuration);
      },
      child: Container(
        color: Colors.transparent,
        height: 36,
        child: AudioFileWaveforms(
          playerController: playerController as PlayerController,
          waveformType: WaveformType.fitWidth,
          size: const Size(double.infinity, 36),
          enableSeekGesture: false,
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
    );
  }

  // ✅ Visualizador alternativo para web
  Widget _buildWebAudioVisualizer(BuildContext context, Duration effectiveMaxDuration) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _handleSeekGesture(context, details.globalPosition, effectiveMaxDuration);
      },
      onTapDown: (details) {
        _handleSeekGesture(context, details.globalPosition, effectiveMaxDuration);
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Barra de progreso
              if (effectiveMaxDuration > Duration.zero)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final progress = duration.inMilliseconds /
                        effectiveMaxDuration.inMilliseconds;
                    return Container(
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDF48A5), Color(0xFFE066B5)],
                        ),
                      ),
                    );
                  },
                ),
              
              // Líneas simulando waveform
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(30, (index) {
                    final heights = [0.3, 0.5, 0.7, 0.9, 0.6, 0.4];
                    final height = heights[index % heights.length];
                    return Container(
                      width: 2,
                      height: 36 * height,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSeekGesture(
    BuildContext context,
    Offset globalPosition,
    Duration effectiveMaxDuration,
  ) {
    if (effectiveMaxDuration == Duration.zero) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(globalPosition);
    final width = box.size.width;
    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (effectiveMaxDuration.inMilliseconds * ratio).round(),
    );
    onSeek(newPosition);
  }
}