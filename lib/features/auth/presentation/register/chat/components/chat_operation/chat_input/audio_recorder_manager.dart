// audio_recorder_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart' as ja;

class AudioRecorderManager {
  // Estado público
  bool isRecording = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration maxDuration = Duration.zero;
  String? audioPath;

  // Internos
  final _recorder = AudioRecorder();

  // Controllers
  late RecorderController waveController;
  late PlayerController playerController; // Para AudioFileWaveforms
  final AudioPlayer _audioPlayer = AudioPlayer(); // Para reproducción real

  // Subscriptions - CORREGIDO: Tipos correctos
  StreamSubscription<int?>? _playerControllerDurationSub;
  StreamSubscription? _playerControllerCompletionSub;
  StreamSubscription<Duration>? _waveRecordingDurationSub;
  StreamSubscription<Duration>? _audioPlayerPositionSub;
  StreamSubscription<Duration?>? _audioPlayerDurationSub;  // ✅ Duration? (nullable)
  StreamSubscription<ja.PlayerState>? _audioPlayerStateSub;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    _initializeControllers();
  }

  PlayerController get waveformPlayerController => playerController;

  void _initializeControllers() {
    // RecorderController (grabación)
    waveController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100
      ..bitRate = 128000;

    // PlayerController (waveform visual)
    playerController = PlayerController();

    // Cancelar subscripciones previas
    _cancelSubscriptions();

    // 1️⃣ Duración del playerController (visual waveform)
    _playerControllerDurationSub =
        playerController.onCurrentDurationChanged.listen((ms) {
      duration = Duration(milliseconds: ms);
      onStateChanged?.call();
    });

    // 2️⃣ Cuando termina la reproducción visual
    _playerControllerCompletionSub =
        playerController.onCompletion.listen((_) async {
      isPlaying = false;
      onStateChanged?.call();
    });

    // 3️⃣ Durante la grabación 
    _waveRecordingDurationSub =
        waveController.onCurrentDuration.listen((ms) {
      if (isRecording) {
        duration = ms;
        onStateChanged?.call();
      }
    });

    // 4️⃣ Streams de just_audio
    _audioPlayerPositionSub = _audioPlayer.positionStream.listen((pos) {
      duration = pos;
      onStateChanged?.call();
    });

    // ✅ CORREGIDO: Sin casting forzado
    _audioPlayerDurationSub = _audioPlayer.durationStream.listen((d) {
      if (d != null) {
        maxDuration = d;
        onStateChanged?.call();
      }
    });

    _audioPlayerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        isPlaying = false;
        duration = Duration.zero;
        try {
          playerController.seekTo(0);
        } catch (_) {}
        waveController.refresh();
        onStateChanged?.call();
      }
    });
  }

  Future<void> startRecording() async {
    debugPrint('🎙️ [AudioManager] Iniciando grabación...');

    if (audioPath != null) {
      debugPrint('🔄 [AudioManager] Limpiando audio previo...');
      await reset();
    }

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

    // Iniciar waveController (grabación visual)
    await waveController.record(path: path);

    isRecording = true;
    duration = Duration.zero;
    audioPath = path;

    onStateChanged?.call();
  }

  Future<void> stopRecording() async {
    debugPrint('⏹️ [AudioManager] Deteniendo grabación...');

    final path = await _recorder.stop();
    await waveController.stop();
    isRecording = false;
    audioPath = path;

    if (path != null) {
      try {
        await playerController.preparePlayer(
          path: path,
          shouldExtractWaveform: true,
          noOfSamples: 120,
        );

        if (playerController.maxDuration > 0) {
          maxDuration = Duration(milliseconds: playerController.maxDuration);
        } else {
          await _audioPlayer.setFilePath(path);
          final d = await _audioPlayer.load();
          if (d != null) maxDuration = d;
        }
      } catch (e) {
        debugPrint('⚠️ [AudioManager] preparePlayer fallback: $e');
        await _audioPlayer.setFilePath(path);
        final d = await _audioPlayer.load();
        if (d != null) maxDuration = d;
      }

      duration = Duration.zero;
      debugPrint('✅ [AudioManager] Grabación finalizada: $path');
      debugPrint('✅ [AudioManager] Duración: ${maxDuration.inSeconds}s');
      onStateChanged?.call();
    }
  }

  Future<void> playRecording() async {
    if (audioPath == null) return;

    if (duration >= maxDuration && maxDuration > Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
      duration = Duration.zero;
      try {
        playerController.seekTo(0);
      } catch (_) {}
      waveController.refresh();
    }

    if (!isPlaying) {
      await _audioPlayer.setFilePath(audioPath!);
      await _audioPlayer.play();
    }

    isPlaying = true;
    onStateChanged?.call();
  }

  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
    isPlaying = false;
    duration = Duration.zero;
    try {
      playerController.seekTo(0);
    } catch (_) {}
    waveController.refresh();
    onStateChanged?.call();
  }

  Future<void> seekToPosition(Duration position) async {
    if (audioPath == null) return;
    final wasPlaying = isPlaying;
    try {
      await _audioPlayer.seek(position);
      // sincronizar visual
      playerController.seekTo(position.inMilliseconds); 
      duration = position;
      onStateChanged?.call();
      if (wasPlaying) await _audioPlayer.play();
    } catch (e) {
      debugPrint('⚠️ [AudioManager] seek error: $e');
    }
  }

  Future<void> reset() async {
    debugPrint('🔄 [AudioManager] Iniciando reset completo...');
    try {
      if (isPlaying) {
        await _audioPlayer.stop();
        isPlaying = false;
      }
      if (isRecording) {
        await _recorder.stop();
        await waveController.stop();
        isRecording = false;
      }

      if (audioPath != null) {
        try {
          final file = File(audioPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ [AudioManager] Archivo temporal eliminado');
          }
        } catch (e) {
          debugPrint('⚠️ [AudioManager] Error eliminando archivo: $e');
        }
      }

      try {
        waveController.dispose();
      } catch (_) {}
      try {
        playerController.dispose();
      } catch (_) {}

      _cancelSubscriptions();

      audioPath = null;
      duration = Duration.zero;
      maxDuration = Duration.zero;
      isRecording = false;
      isPlaying = false;

      _initializeControllers();

      debugPrint('✅ [AudioManager] Reset completo exitoso');
      onStateChanged?.call();
    } catch (e) {
      debugPrint('❌ [AudioManager] Error en reset: $e');
      _initializeControllers();
      onStateChanged?.call();
    }
  }

  void _cancelSubscriptions() {
    _playerControllerDurationSub?.cancel();
    _playerControllerDurationSub = null;
    _playerControllerCompletionSub?.cancel();
    _playerControllerCompletionSub = null;
    _waveRecordingDurationSub?.cancel();
    _waveRecordingDurationSub = null;
    _audioPlayerPositionSub?.cancel();
    _audioPlayerPositionSub = null;
    _audioPlayerDurationSub?.cancel();
    _audioPlayerDurationSub = null;
    _audioPlayerStateSub?.cancel();
    _audioPlayerStateSub = null;
  }

  void dispose() {
    debugPrint('🔄 [AudioManager] Disposing...');
    _cancelSubscriptions();
    try {
      _recorder.dispose();
    } catch (_) {}
    try {
      waveController.dispose();
    } catch (_) {}
    try {
      playerController.dispose();
    } catch (_) {}
    try {
      _audioPlayer.dispose();
    } catch (_) {}
  }
}