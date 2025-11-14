import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:migozz_app/core/color.dart';

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
  late final PlayerController _player;
  Duration _max = Duration.zero;
  bool _isPlaying = false;
  bool _isPrepared = false;
  bool _isDownloading = false;
  bool _hasError = false;
  // Keep track of download cancelation
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _player = PlayerController();
    _player.onCurrentDurationChanged.listen((ms) {
      if (!mounted) return;
    });

    _player.onCompletion.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      widget.chatController?.onAudioFinished?.call();
    });

    _prepare();
  }

  Future<void> _prepare() async {
    try {
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

      // prepare player with local path
      await _player.preparePlayer(
        path: pathToPlay,
        shouldExtractWaveform: true,
      );
      _max = Duration(milliseconds: _player.maxDuration);
      if (!mounted) return;
      setState(() {
        _isPrepared = true;
        _isDownloading = false;
        _hasError = false;
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
    if (_hasError || !_isPrepared) return;
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
  void dispose() {
    try {
      _player.dispose();
    } catch (_) {}
    // cancel any pending http client
    try {
      _httpClient?.close();
    } catch (_) {}
    // optional: delete temp file
    // if (_localPath != null) File(_localPath!).delete().ignore();
    super.dispose();
  }

  String get _formattedTime {
    final total = _max;
    final sec = total.inSeconds;
    final m = (sec ~/ 60).toString();
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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
                      : SizedBox(
                          height: 36,
                          child: _isPrepared
                              ? AudioFileWaveforms(
                                  playerController: _player,
                                  waveformType: WaveformType.fitWidth,
                                  size: const Size(double.infinity, 36),
                                  playerWaveStyle: PlayerWaveStyle(
                                    fixedWaveColor: const Color(0xFF555555),
                                    liveWaveGradient:
                                        LinearGradient(
                                          colors:
                                              AppColors.primaryGradient.colors,
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 24),
                                        ),
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
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    _isPrepared ? _formattedTime : '--:--',
                    style: const TextStyle(
                      fontSize: 12,
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
