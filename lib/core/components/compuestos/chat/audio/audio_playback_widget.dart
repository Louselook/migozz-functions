import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/color.dart';

/// Widget horizontal para reproducir audio grabado por el usuario
/// Diseño tipo mensaje con waveform horizontal y botón de play/pause
class AudioPlaybackWidget extends StatefulWidget {
  const AudioPlaybackWidget({
    super.key,
    required this.audioPath,
    this.other = false,
    this.chatController,
  });

  final String audioPath;
  final bool other;
  final dynamic chatController;

  @override
  State<AudioPlaybackWidget> createState() => _AudioPlaybackWidgetState();
}

class _AudioPlaybackWidgetState extends State<AudioPlaybackWidget> {
  late final PlayerController _player;
  Duration _current = Duration.zero;
  Duration _max = Duration.zero;
  bool _isPlaying = false;
  bool _isPrepared = false;

  @override
  void initState() {
    super.initState();
    _player = PlayerController();

    // Escuchar cambios en la duración actual
    _player.onCurrentDurationChanged.listen((ms) {
      if (!mounted) return;
      setState(() => _current = Duration(milliseconds: ms));
    });

    // Al finalizar el audio
    _player.onCompletion.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _current = _max;
      });

      // Notificar al controller que terminó el audio
      widget.chatController?.onAudioFinished();
    });

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.preparePlayer(
        path: widget.audioPath,
        shouldExtractWaveform: true,
      );
      _max = Duration(milliseconds: _player.maxDuration);
      setState(() {
        _current = _max;
        _isPrepared = true;
      });
    } catch (e) {
      debugPrint('❌ Error preparando audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = _current.inMinutes;
    final s = (_current.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlayPause() async {
    if (!_isPrepared) return;

    if (_isPlaying) {
      await _player.pausePlayer();
      if (!mounted) return;
      setState(() => _isPlaying = false);
    } else {
      await _player.startPlayer();
      if (!mounted) return;
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con logo y nombre (estilo OtherMessage)
          Row(
            children: [
              SvgPicture.asset(
                "assets/icons/Migozz_SinFONDO.svg",
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                "Migozz",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reproductor de audio horizontal
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de play/pause
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDF48A5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Waveform horizontal
                  SizedBox(
                    width: 200,
                    height: 24,
                    child: AudioFileWaveforms(
                      playerController: _player,
                      waveformType: WaveformType.fitWidth,
                      size: const Size(200, 24),
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

                  const SizedBox(width: 12),

                  // Tiempo
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
