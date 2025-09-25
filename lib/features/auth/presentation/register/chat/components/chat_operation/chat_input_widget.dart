import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_attachment_sheet.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(String path)?
  onSendAudio; // 🔹 callback para enviar audio
  final void Function(String path)? onSendImage;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    this.onSendAudio,
    this.onSendImage,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _showAttachments = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _maxDuration = Duration.zero;
  Timer? _timer;

  final _recorder = AudioRecorder();
  late final RecorderController _waveController;
  late final PlayerController _playerController;

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    _waveController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100
      ..bitRate = 128000;

    _playerController = PlayerController();

    // Sincroniza duración de reproducción
    _playerController.onCurrentDurationChanged.listen((d) {
      setState(() {
        _duration = Duration(milliseconds: d);
      });
    });

    _playerController.onCompletion.listen((_) {
      setState(() {
        _isPlaying = false;
        _duration = _maxDuration;
      });
    });

    widget.controller.addListener(() {
      setState(() {});
    });
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_note.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    await _waveController.record(path: path);

    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
      _audioPath = path;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    await _waveController.stop();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _audioPath = path;
      _duration = Duration.zero;
    });
  }

  Future<void> playRecording() async {
    if (_audioPath == null) return;

    await _playerController.preparePlayer(
      path: _audioPath!,
      shouldExtractWaveform: true,
    );

    _maxDuration = Duration(milliseconds: _playerController.maxDuration);

    await _playerController.startPlayer();
    setState(() => _isPlaying = true);
  }

  Future<void> stopPlaying() async {
    await _playerController.stopPlayer();
    setState(() => _isPlaying = false);
  }

  Future<void> seekToPosition(Duration position) async {
    await _playerController.seekTo(position.inMilliseconds);
    setState(() => _duration = position);
  }

  String formatDuration(Duration d) =>
      "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _recorder.dispose();
    _waveController.dispose();
    _playerController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Adjuntos
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _showAttachments
              ? ChatAttachmentGrid(
                  onSendImage: (path) {
                    widget.onSendImage?.call(path);
                    setState(() => _showAttachments = false); // cierra el panel
                  },
                )
              : null,
        ),

        // Input + audio
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: _isRecording
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textInputBackGround,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AudioWaveforms(
                                size: const Size(double.infinity, 40),
                                recorderController: _waveController,
                                enableGesture: false,
                                waveStyle: const WaveStyle(
                                  waveColor: Colors.red,
                                  extendWaveform: true,
                                  showMiddleLine: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatDuration(_duration),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    : (_audioPath != null
                          ? GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) async {
                                final box =
                                    context.findRenderObject() as RenderBox;
                                final localX = details.localPosition.dx.clamp(
                                  0.0,
                                  box.size.width,
                                );
                                final newPos =
                                    (localX / box.size.width) *
                                    _maxDuration.inMilliseconds;
                                await seekToPosition(
                                  Duration(milliseconds: newPos.toInt()),
                                );
                              },
                              onTapDown: (details) async {
                                final box =
                                    context.findRenderObject() as RenderBox;
                                final localX = details.localPosition.dx.clamp(
                                  0.0,
                                  box.size.width,
                                );
                                final newPos =
                                    (localX / box.size.width) *
                                    _maxDuration.inMilliseconds;
                                await seekToPosition(
                                  Duration(milliseconds: newPos.toInt()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textInputBackGround,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AudioFileWaveforms(
                                        size: const Size(double.infinity, 40),
                                        playerController: _playerController,
                                        waveformType: WaveformType.fitWidth,
                                        playerWaveStyle: const PlayerWaveStyle(
                                          waveThickness: 2,
                                          spacing: 4,
                                          showBottom: true,
                                          showTop: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatDuration(_duration),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        color: Colors.blue,
                                      ),
                                      onPressed: _isPlaying
                                          ? stopPlaying
                                          : playRecording,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : CustomTextField(
                              controller: widget.controller,
                              hintText: "Escribe algo...",
                              radius: 8,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showAttachments
                                      ? Icons.close
                                      : Icons.attach_file,
                                  color: _showAttachments
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: _toggleAttachments,
                              ),
                            )),
              ),
              const SizedBox(width: 6),
              Container(
                height: 48,
                width: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.verticalPinkPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    hasText
                        ? Icons.send_outlined
                        : (_isRecording
                              ? Icons.stop
                              : (_audioPath != null ? Icons.send : Icons.mic)),
                    color: Colors.white,
                  ),
                  onPressed: hasText
                      ? widget.onSend
                      : (_isRecording
                            ? stopRecording
                            : (_audioPath != null
                                  ? () {
                                      widget.onSendAudio?.call(_audioPath!);
                                      setState(() {
                                        _audioPath = null;
                                        _duration = Duration.zero;
                                      });
                                    }
                                  : startRecording)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
