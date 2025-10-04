import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_typing.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/social_cards/social_cards.dart';

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

    // 🔹 Mensajes de audio para reproducir (diseño horizontal con barra de progreso)
    if (message["type"] == MessageType.audioPlayback) {
      final audioPath = message["audio"] as String;
      final other = message["other"] == true;
      final chatController = message["chatController"];

      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: other
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            AudioPlaybackWidget(
              audioPath: audioPath,
              other: other,
              chatController: chatController,
            ),
          ],
        ),
      );
    }

    // 🔹 Mensajes de texto y social cards
    if (message["other"] == true) {
      if (message["social"] == true) {
        final platformData = message["platform"] as Map<String, dynamic>;
        return SocialCardMini(platformData: platformData);
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

class AudioPlaybackWidget extends StatefulWidget {
  const AudioPlaybackWidget({
    super.key,
    required this.audioPath,
    this.other = false,
    this.chatController,
  });

  final String audioPath;
  final bool other;
  final dynamic chatController; // Usar dynamic para evitar import circular

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
      // Notificar que terminó el audio
      if (widget.chatController != null) {
        widget.chatController.onAudioFinished();
      }
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
    } catch (_) {
      // log error
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

  Future<void> _onPlayPause() async {
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
        color: Colors.grey[900], // Mismo color que OtherMessage
        borderRadius: BorderRadius.circular(
          16,
        ), // Mismo radius que OtherMessage
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con logo y nombre - igual que OtherMessage
          Row(
            children: [
              Image(
                image: AssetImage("assets/icons/Migozz300x.png"),
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

          // Reproduktor de audio
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(
                0xFF1E1E1E,
              ), // Fondo oscuro para el reproductor
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de play
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: _onPlayPause,
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

                  // Waveform - con formas reales de volumen como la imagen
                  SizedBox(
                    width: 200,
                    height: 24,
                    child: AudioFileWaveforms(
                      playerController: _player,
                      waveformType: WaveformType.fitWidth,
                      size: const Size(200, 24),
                      playerWaveStyle: PlayerWaveStyle(
                        fixedWaveColor: Color(0xFF555555),
                        liveWaveGradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppColors.primaryGradient.colors,
                        ).createShader(Rect.fromLTWH(0, 0, 200, 24)),
                        waveThickness: 1.2,
                        spacing: 1.8,
                        showBottom: true,
                        showTop: true,
                        scaleFactor:
                            150.0, // Aumentar para montañitas más altas
                        waveCap: StrokeCap.round,
                        showSeekLine: false, // Sin línea en el medio
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tiempo
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _mmss,
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
