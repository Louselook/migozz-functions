import 'dart:io';
import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioPlaybackWidget extends StatefulWidget {
  const AudioPlaybackWidget({
    super.key,
    required this.audioPath,
    this.other = false,
    this.chatController,
    this.otherUserName,
    this.otherUserAvatar,
  });

  final String audioPath; // puede ser URL http(s) o path local
  final bool other;
  final dynamic chatController;
  final String? otherUserName;
  final String? otherUserAvatar;

  @override
  State<AudioPlaybackWidget> createState() => _AudioPlaybackWidgetState();
}

class _AudioPlaybackWidgetState extends State<AudioPlaybackWidget> {
  PlayerController? _player;
  StreamSubscription<int>? _positionSub;
  StreamSubscription<void>? _completionSub;
  Duration _max = Duration.zero;
  Duration _current = Duration.zero;
  bool _isPlaying = false;
  bool _isPrepared = false;
  bool _isDownloading = false;
  bool _hasError = false;
  bool _isSeeking = false; // Para saber si el usuario está arrastrando
  String? _localPath; // Path local del audio (para reinicializar)
  Key _waveformKey = UniqueKey(); // Key para forzar rebuild del waveform
  // Keep track of download cancelation
  http.Client? _httpClient;

  bool _isDisposed = false;
  bool _isResetting = false;
  int _playerSeq = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _prepare();
  }

  void _disposePlayer() {
    try {
      _positionSub?.cancel();
    } catch (_) {}
    _positionSub = null;

    try {
      _completionSub?.cancel();
    } catch (_) {}
    _completionSub = null;

    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  void _wirePlayerListeners(int seq) {
    final p = _player;
    if (p == null) return;

    // 🎵 Escuchar cambios de posición para sincronizar el waveform y tiempo actual
    _positionSub = p.onCurrentDurationChanged.listen((ms) {
      if (_isDisposed || !mounted || _isSeeking) return;
      if (seq != _playerSeq) return;
      setState(() {
        _current = Duration(milliseconds: ms);
      });
    });

    _completionSub = p.onCompletion.listen((_) async {
      if (_isDisposed || !mounted) return;
      if (seq != _playerSeq) return;
      if (_isResetting) return;
      _isResetting = true;
      try {
        debugPrint('🔄 [AudioPlayback] Audio completado - reiniciando player');
        await _resetPlayer();
        if (!_isDisposed) {
          widget.chatController?.onAudioFinished?.call();
        }
      } finally {
        _isResetting = false;
      }
    });
  }

  void _initPlayer() {
    _playerSeq++;
    _disposePlayer();
    _player = PlayerController();
    _wirePlayerListeners(_playerSeq);
  }

  /// 🔄 Reinicia el player completamente para resetear el waveform visual
  Future<void> _resetPlayer() async {
    if (_localPath == null) return;
    if (_isDisposed) return;

    try {
      final seqAtStart = _playerSeq;

      // Pausar si está reproduciendo
      if (_isPlaying) {
        try {
          await _player?.pausePlayer();
        } catch (_) {}
      }

      if (_isDisposed || !mounted) return;
      if (seqAtStart != _playerSeq) return;

      // Disponer el player actual
      _disposePlayer();

      // Crear nuevo player
      _playerSeq++;
      final newSeq = _playerSeq;
      _player = PlayerController();
      _wirePlayerListeners(newSeq);

      if (_isDisposed || !mounted) return;

      // Re-preparar el player con el mismo archivo
      final p = _player;
      if (p == null) return;

      await p.preparePlayer(path: _localPath!, shouldExtractWaveform: true);

      if (_isDisposed || !mounted) return;
      if (newSeq != _playerSeq) return;

      setState(() {
        _isPlaying = false;
        _current = Duration.zero;
        _isPrepared = true;
        _waveformKey = UniqueKey(); // Forzar rebuild del widget waveform
      });

      debugPrint('✅ [AudioPlayback] Player reiniciado correctamente');
    } catch (e) {
      debugPrint('❌ [AudioPlayback] Error reiniciando player: $e');
    }
  }

  Future<void> _prepare() async {
    try {
      final seqAtStart = _playerSeq;
      final src = widget.audioPath;
      String pathToPlay = src;

      if (src.startsWith('http')) {
        // download to temp
        setState(() {
          _isDownloading = true;
          _hasError = false;
        });
        _httpClient = http.Client();
        final resp = await _httpClient!.get(Uri.parse(src));
        if (resp.statusCode != 200) {
          throw Exception('Failed to download audio: ${resp.statusCode}');
        }
        final dir = await getTemporaryDirectory();
        final filename =
            'chat_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(resp.bodyBytes);
        pathToPlay = file.path;
      }

      if (_isDisposed || !mounted) return;
      if (seqAtStart != _playerSeq) return;

      // Guardar el path local para poder reinicializar después
      _localPath = pathToPlay;

      // prepare player with local path
      final p = _player;
      if (p == null) return;
      await p.preparePlayer(path: pathToPlay, shouldExtractWaveform: true);

      if (_isDisposed || !mounted) return;
      if (seqAtStart != _playerSeq) return;

      _max = Duration(milliseconds: p.maxDuration);
      setState(() {
        _isPrepared = true;
        _isDownloading = false;
        _hasError = false;
        _current = Duration.zero;
      });
    } catch (e, st) {
      debugPrint('❌ Audio prepare error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_hasError || !_isPrepared || _player == null || _isDisposed) return;
    if (_isPlaying) {
      try {
        await _player!.pausePlayer();
      } catch (_) {
        return;
      }
      if (!mounted) return;
      setState(() => _isPlaying = false);
    } else {
      try {
        await _player!.startPlayer();
      } catch (_) {
        return;
      }
      if (!mounted) return;
      setState(() => _isPlaying = true);
    }
  }

  /// 🎯 Seek a una posición específica del audio
  Future<void> _seekTo(Duration position) async {
    if (!_isPrepared || _hasError || _player == null || _isDisposed) return;

    final clampedMs = position.inMilliseconds.clamp(0, _max.inMilliseconds);

    try {
      await _player!.seekTo(clampedMs);
      if (!mounted) return;
      setState(() {
        _current = Duration(milliseconds: clampedMs);
      });
    } catch (e) {
      debugPrint('❌ Seek error: $e');
    }
  }

  /// 📍 Calcular posición del seek basado en la posición del toque
  Duration _calculateSeekPosition(Offset localPosition, double width) {
    if (_max == Duration.zero || width <= 0) return Duration.zero;

    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
    return Duration(milliseconds: (_max.inMilliseconds * ratio).round());
  }

  /// 🖐️ Inicio del arrastre (seek)
  void _onSeekStart(Offset localPosition, double width) async {
    if (!_isPrepared || _hasError || _player == null || _isDisposed) return;

    _isSeeking = true;

    // Siempre pausar al iniciar seek y mostrar icono de play
    if (_isPlaying) {
      try {
        await _player!.pausePlayer();
      } catch (_) {}
    }
    setState(() => _isPlaying = false);

    final newPosition = _calculateSeekPosition(localPosition, width);
    debugPrint('🔍 Seek a ${newPosition.inSeconds}s');
    await _seekTo(newPosition);
  }

  /// 🖐️ Durante el arrastre (seek)
  void _onSeekUpdate(Offset localPosition, double width) async {
    if (_isDisposed) return;
    if (!_isSeeking || !_isPrepared || _hasError || _player == null) return;

    final newPosition = _calculateSeekPosition(localPosition, width);
    debugPrint('🔍 Seek a ${newPosition.inSeconds}s');

    // Actualizar la posición visual inmediatamente
    setState(() {
      _current = newPosition;
    });

    await _seekTo(newPosition);
  }

  /// 🖐️ Fin del arrastre (seek) - NO reanuda automáticamente, el usuario debe presionar play
  void _onSeekEnd() {
    _isSeeking = false;
    // El usuario debe presionar play manualmente si quiere continuar
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposePlayer();
    // cancel any pending http client
    try {
      _httpClient?.close();
    } catch (_) {}
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final sec = d.inSeconds;
    final m = (sec ~/ 60).toString();
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _formattedCurrentTime => _formatDuration(_current);
  String get _formattedMaxTime => _formatDuration(_max);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.other ? Colors.grey[900] : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: widget.other
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (widget.other) ...[
            Row(
              children: [
                if (widget.otherUserAvatar != null &&
                    widget.otherUserAvatar!.isNotEmpty)
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(widget.otherUserAvatar!),
                    onBackgroundImageError: (_, __) {},
                    backgroundColor: Colors.grey[800],
                  )
                else if (widget.otherUserName != null &&
                    widget.otherUserName!.isNotEmpty)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.grey[800],
                    child: Text(
                      widget.otherUserName![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                else
                  SvgPicture.asset(
                    "assets/icons/Migozz_SinFONDO.svg",
                    width: 18,
                    height: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  widget.otherUserName ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: (_isDownloading || _hasError)
                      ? null
                      : _togglePlayPause,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDF48A5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _hasError
                      ? const Text(
                          "No se pudo cargar audio",
                          style: TextStyle(color: Colors.redAccent),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final waveWidth = constraints.maxWidth;
                            return GestureDetector(
                              onTapDown: (details) {
                                _onSeekStart(details.localPosition, waveWidth);
                              },
                              onTapUp: (_) {
                                _onSeekEnd();
                              },
                              onHorizontalDragStart: (details) {
                                _onSeekStart(details.localPosition, waveWidth);
                              },
                              onHorizontalDragUpdate: (details) {
                                _onSeekUpdate(details.localPosition, waveWidth);
                              },
                              onHorizontalDragEnd: (_) {
                                _onSeekEnd();
                              },
                              onHorizontalDragCancel: () {
                                _onSeekEnd();
                              },
                              child: Container(
                                color: Colors.transparent,
                                height: 36,
                                child: (_isPrepared && _player != null)
                                    ? AudioFileWaveforms(
                                        key:
                                            _waveformKey, // Key para forzar rebuild
                                        playerController: _player!,
                                        waveformType: WaveformType.fitWidth,
                                        size: Size(waveWidth, 36),
                                        enableSeekGesture:
                                            false, // Manejamos seek manualmente
                                        playerWaveStyle: PlayerWaveStyle(
                                          fixedWaveColor: const Color(
                                            0xFF555555,
                                          ),
                                          liveWaveColor: const Color(
                                            0xFFDF48A5,
                                          ),
                                          seekLineColor: const Color(
                                            0xFFDF48A5,
                                          ),
                                          seekLineThickness: 2.0,
                                          showSeekLine: true,
                                          waveThickness: 1.2,
                                          spacing: 1.8,
                                          showBottom: true,
                                          showTop: true,
                                          scaleFactor: 150.0,
                                          waveCap: StrokeCap.round,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    _isPrepared
                        ? '$_formattedCurrentTime / $_formattedMaxTime'
                        : '--:--',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
