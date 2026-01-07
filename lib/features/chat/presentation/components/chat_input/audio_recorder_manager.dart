// audio_recorder_manager.dart - VERSION SIMPLIFICADA
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioRecorderManager {
  // Estado público
  bool isRecording = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration maxDuration = Duration.zero;
  String? audioPath;

  // Controllers - IGUAL que EditRecordScreen
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late PlayerController playerController;

  // SOLO 2 subscripciones necesarias (como EditRecordScreen)
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    _initializeControllers();
  }

  PlayerController get waveformPlayerController => playerController;

  void _initializeControllers() {
    playerController = PlayerController();
    _cancelSubscriptions();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // Sincronización simple (como EditRecordScreen)
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!isRecording) {
        duration = position;
        // SOLO sincronizar visual, SIN interferir con reproducción
        try {
          playerController.seekTo(position.inMilliseconds);
        } catch (_) {}
        onStateChanged?.call();
      }
    });

    // Detectar fin de reproducción
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = isPlaying;
      isPlaying = state.playing;

      if (state.processingState == ProcessingState.completed) {
        isPlaying = false;
        duration = Duration.zero;
        try {
          playerController.seekTo(0);
        } catch (_) {}
        onStateChanged?.call();
      } else if (wasPlaying != isPlaying) {
        onStateChanged?.call();
      }
    });
  }

  Future<void> startRecording() async {
    debugPrint('🎙️ [AudioManager] Iniciando grabación...');

    // Pedir/validar permiso de micrófono justo al grabar.
    // Esto evita solicitar permisos al inicio de la app.
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      debugPrint('⛔ [AudioManager] Permiso de micrófono denegado');
      throw Exception('microphone_permission_denied');
    }

    if (audioPath != null) {
      await reset();
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Configuración SIMPLE como EditRecordScreen
    await _recorder.start(const RecordConfig(), path: path);

    isRecording = true;
    duration = Duration.zero;
    audioPath = path;
    onStateChanged?.call();

    // Timer manual para duración (más confiable)
    _startDurationTimer();
  }

  Timer? _durationTimer;

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isRecording) {
        duration = Duration(milliseconds: duration.inMilliseconds + 100);
        onStateChanged?.call();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> stopRecording() async {
    debugPrint('⏹️ [AudioManager] Deteniendo grabación...');

    _durationTimer?.cancel();
    final path = await _recorder.stop();
    isRecording = false;
    audioPath = path;

    if (path != null && File(path).existsSync()) {
      try {
        // Preparar waveform SOLO para visualización
        await playerController.preparePlayer(
          path: path,
          shouldExtractWaveform: true,
          noOfSamples: 120,
        );

        // Configurar just_audio para reproducción
        await _audioPlayer.setFilePath(path);
        final d = await _audioPlayer.load();
        if (d != null) {
          maxDuration = d;
        }
      } catch (e) {
        debugPrint('⚠️ Error preparando audio: $e');
      }

      duration = Duration.zero;
      debugPrint('✅ Grabación finalizada: $path (${maxDuration.inSeconds}s)');
      onStateChanged?.call();
    }
  }

  Future<void> playRecording() async {
    if (audioPath == null) return;

    try {
      // Configurar estado igual que EditRecordScreen
      if (_audioPlayer.playerState.processingState == ProcessingState.idle ||
          _audioPlayer.playerState.processingState ==
              ProcessingState.completed) {
        await _audioPlayer.setFilePath(audioPath!);
      }

      // Resetear si llegó al final
      if (_audioPlayer.position >= (_audioPlayer.duration ?? Duration.zero)) {
        await _audioPlayer.seek(Duration.zero);
        try {
          playerController.seekTo(0);
        } catch (_) {}
      }

      await _audioPlayer.play();

      // EXPERIMENTAL: Probar si startPlayer ayuda (como EditRecordScreen)
      try {
        await playerController.startPlayer();
      } catch (_) {}

      debugPrint('🎵 Reproduciendo audio');
    } catch (e) {
      debugPrint('❌ Error reproduciendo: $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.pause();

      // También pausar PlayerController (como EditRecordScreen)
      try {
        await playerController.pausePlayer();
      } catch (_) {}

      debugPrint('⏸️ Audio pausado');
    } catch (e) {
      debugPrint('❌ Error pausando: $e');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (audioPath == null) return;

    try {
      final wasPlaying = isPlaying;

      await _audioPlayer.seek(position);
      try {
        playerController.seekTo(position.inMilliseconds);
      } catch (_) {}

      // Continuar reproduciendo si estaba sonando
      if (wasPlaying) {
        await _audioPlayer.play();
      }

      debugPrint('🔍 Seek a ${position.inSeconds}s');
    } catch (e) {
      debugPrint('⚠️ Error en seek: $e');
    }
  }

  Future<void> clearReferences() async {
    debugPrint('🧹 [AudioManager] Limpiando referencias (sin borrar archivo)...');

    try {
      _durationTimer?.cancel();

      if (isPlaying) {
        await _audioPlayer.stop();
        isPlaying = false;
      }

      if (isRecording) {
        await _recorder.stop();
        isRecording = false;
      }

      // NO eliminar el archivo físico, solo limpiar la referencia
      // El archivo será manejado por AudioChatHandler

      try {
        playerController.dispose();
      } catch (_) {}

      _cancelSubscriptions();

      // Reset estado visual
      audioPath = null;
      duration = Duration.zero;
      maxDuration = Duration.zero;
      isRecording = false;
      isPlaying = false;

      _initializeControllers();
      onStateChanged?.call();
      
      debugPrint('✅ [AudioManager] Referencias limpiadas (archivo preservado)');
    } catch (e) {
      debugPrint('❌ Error en clearReferences: $e');
      _initializeControllers();
      onStateChanged?.call();
    }
  }

  Future<void> reset() async {
    debugPrint('🔄 Reset AudioManager...');

    try {
      _durationTimer?.cancel();

      if (isPlaying) {
        await _audioPlayer.stop();
        isPlaying = false;
      }

      if (isRecording) {
        await _recorder.stop();
        isRecording = false;
      }

      // Aquí SÍ eliminar el archivo
      if (audioPath != null) {
        try {
          final file = File(audioPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ [AudioManager] Archivo eliminado: $audioPath');
          }
        } catch (e) {
          debugPrint('⚠️ Error eliminando archivo: $e');
        }
      }

      try {
        playerController.dispose();
      } catch (_) {}

      _cancelSubscriptions();

      // Reset estado
      audioPath = null;
      duration = Duration.zero;
      maxDuration = Duration.zero;
      isRecording = false;
      isPlaying = false;

      _initializeControllers();
      onStateChanged?.call();
    } catch (e) {
      debugPrint('❌ Error en reset: $e');
      _initializeControllers();
      onStateChanged?.call();
    }
  }

  void _cancelSubscriptions() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _durationTimer?.cancel();
  }

  void dispose() {
    debugPrint('🔄 Disposing AudioManager...');
    _cancelSubscriptions();
    try {
      _recorder.dispose();
      playerController.dispose();
      _audioPlayer.dispose();
    } catch (_) {}
  }
}

class AudioUtils {
  static String formatDuration(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
