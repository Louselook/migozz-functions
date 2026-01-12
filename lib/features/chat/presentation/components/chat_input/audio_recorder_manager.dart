// audio_recorder_manager.dart - VERSION SIMPLIFICADA
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  // Key para forzar rebuild del waveform widget
  Key waveformKey = UniqueKey();

  // 🎙️ Amplitud de audio en tiempo real (0.0 a 1.0)
  double currentAmplitude = 0.0;

  double _smoothedAmplitude = 0.0;

  // Hysteresis gate to keep silence stable across devices.
  static const double _openGateDb = -40.0;
  static const double _closeGateDb = -48.0;
  static const double _attack = 0.55;
  static const double _release = 0.20;

  bool _gateOpen = false;

  // Controllers - IGUAL que EditRecordScreen
  final AudioRecorder _recorder = AudioRecorder();
  late PlayerController playerController;

  // Subscripciones para preview (playerController-driven, same as chat)
  StreamSubscription<int>? _playerPositionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompletionSubscription;
  StreamSubscription? _amplitudeSubscription;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    _initializeControllers();
  }

  PlayerController get waveformPlayerController => playerController;

  void _initializeControllers() {
    playerController = PlayerController();
    // Smoother progress updates.
    playerController.updateFrequency = UpdateFrequency.high;
    _cancelSubscriptions();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _playerPositionSubscription = playerController.onCurrentDurationChanged
        .listen((ms) {
          if (isRecording || audioPath == null) return;
          duration = Duration(milliseconds: ms);
          onStateChanged?.call();
        });

    _playerStateSubscription = playerController.onPlayerStateChanged.listen((
      state,
    ) {
      final wasPlaying = isPlaying;
      isPlaying = state == PlayerState.playing;
      if (wasPlaying != isPlaying) {
        onStateChanged?.call();
      }
    });

    _playerCompletionSubscription = playerController.onCompletion.listen((
      _,
    ) async {
      isPlaying = false;
      duration = Duration.zero;

      // Reiniciar el player completamente para resetear el waveform visual
      await _resetPlayerForVisualReset();

      onStateChanged?.call();
    });
  }

  double _normalizeDbToUnit(double db) {
    if (db.isNaN || db.isInfinite) return 0.0;

    // Hysteresis: require a higher db to open than to stay open.
    if (_gateOpen) {
      if (db <= _closeGateDb) {
        _gateOpen = false;
        return 0.0;
      }
    } else {
      if (db >= _openGateDb) {
        _gateOpen = true;
      } else {
        return 0.0;
      }
    }

    // Map [_closeGateDb .. 0] -> [0 .. 1]
    final v = (db - _closeGateDb) / (0.0 - _closeGateDb);
    return v.clamp(0.0, 1.0);
  }

  double _applyEnvelope(double target) {
    final coeff = target > _smoothedAmplitude ? _attack : _release;
    _smoothedAmplitude =
        _smoothedAmplitude + (target - _smoothedAmplitude) * coeff;
    return _smoothedAmplitude.clamp(0.0, 1.0);
  }

  /// 🔄 Reinicia el player completamente para resetear el waveform visual
  Future<void> _resetPlayerForVisualReset() async {
    if (audioPath == null) return;

    try {
      debugPrint('🔄 [AudioManager] Reiniciando player para reset visual...');

      // Cancelar subscripciones actuales
      _cancelSubscriptions();

      // Disponer el player actual
      try {
        playerController.dispose();
      } catch (_) {}

      // Crear nuevo player
      playerController = PlayerController();
      playerController.updateFrequency = UpdateFrequency.high;

      // Re-preparar el player con el mismo archivo
      await playerController.preparePlayer(
        path: audioPath!,
        shouldExtractWaveform: true,
      );

      // Re-configurar subscripciones
      _setupSubscriptions();

      maxDuration = Duration(milliseconds: playerController.maxDuration);
      duration = Duration.zero;
      isPlaying = false;
      waveformKey = UniqueKey(); // Forzar rebuild del widget waveform

      debugPrint('✅ [AudioManager] Player reiniciado correctamente');
    } catch (e) {
      debugPrint('❌ [AudioManager] Error reiniciando player: $e');
    }
  }

  Future<void> _resetPreviewPlayback() async {
    // Ensure the player returns to start (without clearing waveform).
    try {
      await playerController.pausePlayer();
    } catch (_) {}
    try {
      playerController.seekTo(0);
    } catch (_) {}
  }

  Future<void> _waitForFileStable(
    String path, {
    Duration timeout = const Duration(seconds: 2),
    Duration poll = const Duration(milliseconds: 120),
    int stableTicks = 2,
  }) async {
    final file = File(path);
    final deadline = DateTime.now().add(timeout);
    int sameCount = 0;
    int lastSize = -1;

    while (DateTime.now().isBefore(deadline)) {
      int size;
      try {
        size = await file.length();
      } catch (_) {
        size = -1;
      }

      if (size > 0 && size == lastSize) {
        sameCount++;
        if (sameCount >= stableTicks) return;
      } else {
        sameCount = 0;
        lastSize = size;
      }

      await Future<void>.delayed(poll);
    }
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
    currentAmplitude = 0.0;
    _smoothedAmplitude = 0.0;
    _gateOpen = false;
    audioPath = path;
    onStateChanged?.call();

    // Timer manual para duración (más confiable)
    _startDurationTimer();

    // 🎙️ Escuchar amplitud del micrófono
    _setupAmplitudeListener();
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

  void _setupAmplitudeListener() {
    _amplitudeSubscription?.cancel();

    // record:^6 => onAmplitudeChanged(Duration) returns Stream<Amplitude>
    // This makes the visualizer reactive: it stays low on silence.
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen(
          (amp) {
            if (!isRecording) return;

            final db = (amp.current as num?)?.toDouble() ?? -160.0;
            final target = _normalizeDbToUnit(db);
            final next = _applyEnvelope(target);

            // Extra deadband: treat tiny values as silence to stop "palpitar".
            final snapped = next < 0.06 ? 0.0 : next;

            // Avoid spamming rebuilds if change is tiny.
            if ((snapped - currentAmplitude).abs() < 0.02) return;
            currentAmplitude = snapped;
            onStateChanged?.call();
          },
          onError: (e) {
            debugPrint('⚠️ Error reading mic amplitude: $e');
          },
        );
  }

  Future<void> stopRecording() async {
    debugPrint('⏹️ [AudioManager] Deteniendo grabación...');

    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    final path = await _recorder.stop();
    isRecording = false;
    currentAmplitude = 0.0;
    _smoothedAmplitude = 0.0;
    _gateOpen = false;
    audioPath = path;

    if (path != null && File(path).existsSync()) {
      try {
        // Some devices/codecs finalize the m4a asynchronously. Wait briefly
        // so the extracted waveform matches what will be sent/played later.
        await _waitForFileStable(path);

        // IMPORTANT: Use the same approach as the sent message widget:
        // PlayerController.preparePlayer(shouldExtractWaveform: true).
        await playerController.preparePlayer(
          path: path,
          shouldExtractWaveform: true,
        );

        maxDuration = Duration(milliseconds: playerController.maxDuration);
        duration = Duration.zero;
        isPlaying = false;
        await _resetPreviewPlayback();
      } catch (e) {
        debugPrint('⚠️ Error preparando audio: $e');
      }

      debugPrint('✅ Grabación finalizada: $path (${maxDuration.inSeconds}s)');
      onStateChanged?.call();
    }
  }

  Future<void> playRecording() async {
    if (audioPath == null) return;

    try {
      // Ensure prepared (in case the user left/returned quickly).
      if (playerController.maxDuration <= 0) {
        await _waitForFileStable(audioPath!);
        await playerController.preparePlayer(
          path: audioPath!,
          shouldExtractWaveform: true,
        );
        maxDuration = Duration(milliseconds: playerController.maxDuration);
      }

      // Restart if we are at the end.
      if (maxDuration > Duration.zero && duration >= maxDuration) {
        await _resetPreviewPlayback();
        duration = Duration.zero;
      }

      // Give the UI a short moment to paint before audio starts.
      onStateChanged?.call();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await playerController.startPlayer();
      isPlaying = true;
      onStateChanged?.call();

      debugPrint('🎵 Reproduciendo audio');
    } catch (e) {
      debugPrint('❌ Error reproduciendo: $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      try {
        await playerController.pausePlayer();
      } catch (_) {}

      isPlaying = false;
      onStateChanged?.call();

      debugPrint('⏸️ Audio pausado');
    } catch (e) {
      debugPrint('❌ Error pausando: $e');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (audioPath == null) return;

    try {
      // Siempre pausar al hacer seek (igual que AudioPlaybackWidget)
      if (isPlaying) {
        try {
          await playerController.pausePlayer();
        } catch (_) {}
        isPlaying = false;
      }

      try {
        await playerController.seekTo(position.inMilliseconds);
      } catch (_) {}

      duration = position;
      onStateChanged?.call();

      debugPrint('🔍 Seek a ${position.inSeconds}s');
    } catch (e) {
      debugPrint('⚠️ Error en seek: $e');
    }
  }

  Future<void> clearReferences() async {
    debugPrint(
      '🧹 [AudioManager] Limpiando referencias (sin borrar archivo)...',
    );

    try {
      _durationTimer?.cancel();

      if (isPlaying) {
        try {
          await playerController.stopPlayer();
        } catch (_) {}
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
        try {
          await playerController.stopPlayer();
        } catch (_) {}
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
    _playerPositionSubscription?.cancel();
    _playerPositionSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _playerCompletionSubscription?.cancel();
    _playerCompletionSubscription = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _durationTimer?.cancel();
  }

  void dispose() {
    debugPrint('🔄 Disposing AudioManager...');
    _cancelSubscriptions();
    try {
      _recorder.dispose();
      playerController.dispose();
    } catch (_) {}
  }
}

class AudioUtils {
  static String formatDuration(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
