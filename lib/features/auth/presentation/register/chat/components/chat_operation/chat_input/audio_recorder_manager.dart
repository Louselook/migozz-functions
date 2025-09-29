import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioRecorderManager {
  bool isRecording = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration maxDuration = Duration.zero;
  String? audioPath;

  final _recorder = AudioRecorder();
  late final RecorderController waveController;
  late final PlayerController playerController;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    waveController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100
      ..bitRate = 128000;

    playerController = PlayerController();

    // duración del reproductor
    playerController.onCurrentDurationChanged.listen((ms) {
      duration = Duration(milliseconds: ms);
      onStateChanged?.call();
    });

    // cuando termina la reproducción
    playerController.onCompletion.listen((_) async {
      isPlaying = false;
      duration = Duration.zero;
      await playerController.seekTo(0);
      waveController.refresh(); // mueve la waveform al inicio
      onStateChanged?.call();
    });

    // duración de la grabación
    waveController.onCurrentDuration.listen((d) {
      if (isRecording) {
        duration = d;
        onStateChanged?.call();
      }
    });

    // cuando termina la grabación
    waveController.onRecordingEnded.listen((d) {
      isRecording = false;
      duration = d;
      onStateChanged?.call();
    });
  }

  Future<void> startRecording() async {
    if (!await Permission.microphone.request().isGranted) return;

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    await waveController.record(path: path);

    isRecording = true;
    duration = Duration.zero;
    audioPath = path;
    onStateChanged?.call();
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    await waveController.stop();
    isRecording = false;
    audioPath = path;

    if (path != null) {
      await playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
      );
      maxDuration = Duration(milliseconds: playerController.maxDuration);
      duration = Duration.zero;
      onStateChanged?.call();
    }
  }

  Future<void> playRecording() async {
    if (audioPath == null) return;

    if (duration >= maxDuration) {
      await playerController.seekTo(0);
      duration = Duration.zero;
      waveController.refresh();
    }

    if (!playerController.playerState.isPlaying) {
      await playerController.startPlayer();
    }

    isPlaying = true;
    onStateChanged?.call();
  }

  Future<void> stopPlaying() async {
    await playerController.stopPlayer();
    isPlaying = false;
    duration = Duration.zero;
    waveController.refresh();
    onStateChanged?.call();
  }

  Future<void> seekToPosition(Duration position) async {
    if (audioPath == null) return;

    final wasPlaying = isPlaying;
    if (wasPlaying) await playerController.pausePlayer();

    await playerController.seekTo(position.inMilliseconds);
    duration = position;
    onStateChanged?.call();

    if (wasPlaying) await playerController.startPlayer();
  }

  void reset() {
    audioPath = null;
    duration = Duration.zero;
    maxDuration = Duration.zero;
    isRecording = false;
    isPlaying = false;
    waveController.reset();
    onStateChanged?.call();
  }

  void dispose() {
    _recorder.dispose();
    waveController.dispose();
    playerController.dispose();
  }
}
