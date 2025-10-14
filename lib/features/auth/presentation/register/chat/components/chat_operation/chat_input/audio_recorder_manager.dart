import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioRecorderManager {
  bool isRecording = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration maxDuration = Duration.zero;
  String? audioPath;

  final _recorder = AudioRecorder();
  late RecorderController waveController;
  late PlayerController playerController;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    _initializeControllers();
  }

  // ✅ Método para inicializar/reinicializar controllers
  void _initializeControllers() {
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
      waveController.refresh();
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
    debugPrint('🎙️ [AudioManager] Iniciando grabación...');

    // ✅ Si hay un audio previo, resetear primero
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

    await waveController.record(path: path);

    isRecording = true;
    duration = Duration.zero;
    audioPath = path;

    debugPrint('✅ [AudioManager] Grabación iniciada: $path');
    onStateChanged?.call();
  }

  Future<void> stopRecording() async {
    debugPrint('⏹️ [AudioManager] Deteniendo grabación...');

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

      debugPrint('✅ [AudioManager] Grabación finalizada: $path');
      debugPrint('✅ [AudioManager] Duración: ${maxDuration.inSeconds}s');
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

  // ✅ Reset completo con reinicialización de controllers
  Future<void> reset() async {
    debugPrint('🔄 [AudioManager] Iniciando reset completo...');

    try {
      // 1️⃣ Detener reproducción si está activa
      if (isPlaying) {
        await playerController.stopPlayer();
        isPlaying = false;
      }

      // 2️⃣ Detener grabación si está activa
      if (isRecording) {
        await _recorder.stop();
        await waveController.stop();
        isRecording = false;
      }

      // 3️⃣ Eliminar archivo temporal si existe
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

      // 4️⃣ Disponer controllers actuales
      try {
        waveController.dispose();
        playerController.dispose();
      } catch (e) {
        debugPrint('⚠️ [AudioManager] Error disposing controllers: $e');
      }

      // 5️⃣ Resetear variables
      audioPath = null;
      duration = Duration.zero;
      maxDuration = Duration.zero;
      isRecording = false;
      isPlaying = false;

      // 6️⃣ RECREAR controllers (CRÍTICO para que funcione la siguiente grabación)
      _initializeControllers();

      debugPrint('✅ [AudioManager] Reset completo exitoso');
      onStateChanged?.call();
    } catch (e) {
      debugPrint('❌ [AudioManager] Error en reset: $e');
      // Aún así intentar recrear los controllers
      _initializeControllers();
      onStateChanged?.call();
    }
  }

  void dispose() {
    debugPrint('🔄 [AudioManager] Disposing...');
    _recorder.dispose();
    waveController.dispose();
    playerController.dispose();
  }
}
