import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_typing.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import '../../../../features/auth/presentation/register/chat/components/social_card.dart';

class ChatMessageBuilder {
  static Widget buildMessage(Map<String, dynamic> message) {
    // ia
    if (message["type"] == MessageType.typing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            OtherTyping(
              name:
                  message["name"] ??
                  "IA", // Aquí puedes pasar Juan, José, IA, etc.
            ),
          ],
        ),
      );
    }

    // 🔹 Mensajes de imagen (URL o local)
    if (message["type"] == MessageType.pictureCard) {
      final pics = List<Map<String, String>>.from(message["pictures"]);
      return PictureOptions(
        pictures: pics,
        time: message["time"],
        sender: message["other"],
      );
    }

    // 🔹 Mensajes de audio (diseño circular, centrado, solo reproducir/pausar)
    if (message["type"] == MessageType.audio) {
      final audioPath = message["audio"] as String;
      final other = message["other"] == true;

      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Center(
          child: AudioMessageCircle(
            audioPath: audioPath,
            other: other,
            size: 121,
          ),
        ),
      );
    }

    // 🔹 Mensajes de texto y social cards
    if (message["other"] == true) {
      if (message["social"] == true) {
        return buildSocialCard(
          message["platform"],
          message["stats"],
          message["emoji"],
          message["time"],
        );
      }

      return OtherMessage(
        text: message["text"] ?? "",
        time: message["time"] ?? "",
      );
    } else {
      return UserMessage(text: message["text"] ?? "");
    }
  }
}

class AudioMessageCircle extends StatefulWidget {
  const AudioMessageCircle({
    super.key,
    required this.audioPath,
    this.other = false,
    this.size = 121,
  });

  final String audioPath;
  final bool other;
  final double size;

  @override
  State<AudioMessageCircle> createState() => _AudioMessageCircleState();
}

class _AudioMessageCircleState extends State<AudioMessageCircle> {
  late final PlayerController _player;
  Duration _current = Duration.zero;
  Duration _max = Duration.zero;
  bool _isPlaying = false;
  bool _isPrepared = false;

  @override
  void initState() {
    super.initState();
    _player = PlayerController();

    // Progreso
    _player.onCurrentDurationChanged.listen((ms) {
      if (!mounted) return;
      setState(() => _current = Duration(milliseconds: ms));
    });

    // Al finalizar, mostramos total y quedamos en pausa
    _player.onCompletion.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _current = _max;
      });
    });

    _initPlayer(); // obtenemos la duración real desde el inicio
  }

  Future<void> _initPlayer() async {
    try {
      await _player.preparePlayer(
        path: widget.audioPath,
        shouldExtractWaveform: true,
      );
      _max = Duration(milliseconds: _player.maxDuration);
      setState(() {
        _current = _max; // muestra p.ej. 0:15 desde el inicio
        _isPrepared = true;
      });
    } catch (_) {
      // log
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String get _mmss {
    final m = _current.inMinutes;
    final s = (_current.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onTapCircle() async {
    if (!_isPrepared) return;

    if (_isPlaying) {
      // 🔒 Pausa (no resetea ni permite editar)
      await _player.pausePlayer();
      if (!mounted) return;
      setState(() => _isPlaying = false);
    } else {
      // ▶️ Reanuda / reproduce desde donde iba
      await _player.startPlayer();
      if (!mounted) return;
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTapCircle, // el círculo entero solo hace play/pausa
      onLongPress: null, // evita acciones raras tipo “grabar/editar”
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo circular
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.other
                      ? [const Color(0xFF7B1FA2), const Color(0xFF6A1B9A)]
                      : [const Color(0xFFDF48A5), const Color(0xFF9C27B0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),

            // Waveform separado y abajo del micrófono, adaptable al tamaño
            Positioned(
              bottom:
                  size * 0.15, // Posicionar desde abajo para mayor separación
              left: size * 0.12, // Márgenes laterales proporcionales
              right: size * 0.12,
              child: IgnorePointer(
                ignoring: true, // bloquea cualquier gesto
                child: SizedBox(
                  height: size * 0.22, // Altura proporcional al círculo
                  width: size * 0.76, // Ancho proporcional
                  child: AudioFileWaveforms(
                    playerController: _player,
                    waveformType: WaveformType.fitWidth,
                    size: Size(size * 0.76, size * 0.22),
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: Color(0xFFCF9FE8),
                      liveWaveColor: Color(0xFFCF9FE8),
                      waveThickness: size > 100 ? 2.5 : 2.0, // Grosor adaptable
                      spacing: size > 100 ? 3.0 : 2.5, // Espaciado adaptable
                      showBottom: true,
                      showTop: true,
                      scaleFactor: 0.85,
                    ),
                  ),
                ),
              ),
            ),

            // Ícono play/pausa (no micrófono, no “grabar”)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                _isPlaying ? Icons.mic_off : Icons.mic,
                key: ValueKey(_isPlaying),
                size: size * 0.5,
                color: Color(0xFFCF9FE8),
              ),
            ),

            // Tiempo arriba centrado
            Positioned(
              top: size * 0.10,
              left: 0,
              right: 0,
              child: Text(
                _mmss,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCF9FE8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
