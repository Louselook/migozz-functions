import 'dart:async';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/audio_waveforms_web.dart';
import 'package:record/record.dart';
import 'package:web/web.dart' as web; // ✅ Reemplazar dart:html

class AudioRecorderManager {
  bool isRecording = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration maxDuration = Duration.zero;
  String? audioPath;

  final AudioRecorder _recorder = AudioRecorder();
  web.HTMLAudioElement? _audioElement; // ✅ Usar web.HTMLAudioElement
  Timer? _durationTimer;
  Timer? _playbackTimer;
  late PlayerController playerController;

  VoidCallback? onStateChanged;

  AudioRecorderManager({this.onStateChanged}) {
    playerController = PlayerController();
  }

  PlayerController get waveformPlayerController => playerController;

  Future<void> startRecording() async {
    debugPrint('🎙️ [AudioManager WEB] Iniciando grabación...');

    if (audioPath != null) {
      await reset();
    }

    try {
      if (!await _recorder.hasPermission()) {
        debugPrint('❌ Sin permisos de micrófono');
        return;
      }

      // ✅ Agregar path vacío para web (será ignorado)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
        ),
        path: '', // ✅ Required pero ignorado en web
      );

      isRecording = true;
      duration = Duration.zero;
      onStateChanged?.call();

      _startDurationTimer();
    } catch (e) {
      debugPrint('❌ Error iniciando grabación web: $e');
    }
  }

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
    debugPrint('⏹️ [AudioManager WEB] Deteniendo grabación...');

    _durationTimer?.cancel();
    
    try {
      final path = await _recorder.stop();
      isRecording = false;

      if (path != null) {
        audioPath = path;
        maxDuration = duration;
        duration = Duration.zero;
        
        debugPrint('✅ Grabación finalizada (WEB): $path (${maxDuration.inSeconds}s)');
        onStateChanged?.call();
      }
    } catch (e) {
      debugPrint('❌ Error deteniendo grabación: $e');
    }
  }

  Future<void> playRecording() async {
    if (audioPath == null) return;

    try {
      _audioElement?.pause();
      
      // ✅ Crear elemento de audio con el constructor correcto
      _audioElement = web.HTMLAudioElement();
      _audioElement!.src = audioPath!;
      _audioElement!.play();
      
      isPlaying = true;
      onStateChanged?.call();

      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_audioElement?.ended == true) {
          timer.cancel();
          isPlaying = false;
          duration = Duration.zero;
          onStateChanged?.call();
        } else if (_audioElement != null) {
          // ✅ Acceder a currentTime correctamente
          duration = Duration(
            milliseconds: (_audioElement!.currentTime * 1000).toInt(),
          );
          onStateChanged?.call();
        }
      });

      debugPrint('🎵 Reproduciendo audio (WEB)');
    } catch (e) {
      debugPrint('❌ Error reproduciendo (WEB): $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      _audioElement?.pause();
      _playbackTimer?.cancel();
      isPlaying = false;
      onStateChanged?.call();
      
      debugPrint('⏸️ Audio pausado (WEB)');
    } catch (e) {
      debugPrint('❌ Error pausando (WEB): $e');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (_audioElement == null) return;

    try {
      final wasPlaying = isPlaying;
      
      // ✅ Asignar currentTime correctamente
      _audioElement!.currentTime = position.inMilliseconds / 1000;
      duration = position;
      
      if (wasPlaying && _audioElement!.paused) {
        _audioElement!.play();
      }
      
      onStateChanged?.call();
      debugPrint('🔍 Seek a ${position.inSeconds}s (WEB)');
    } catch (e) {
      debugPrint('⚠️ Error en seek (WEB): $e');
    }
  }

  Future<void> reset() async {
    debugPrint('🔄 Reset AudioManager (WEB)...');

    try {
      _durationTimer?.cancel();
      _playbackTimer?.cancel();

      if (isPlaying) {
        _audioElement?.pause();
        isPlaying = false;
      }

      if (isRecording) {
        await _recorder.stop();
        isRecording = false;
      }

      _audioElement = null;
      audioPath = null;
      duration = Duration.zero;
      maxDuration = Duration.zero;
      
      onStateChanged?.call();
    } catch (e) {
      debugPrint('❌ Error en reset (WEB): $e');
    }
  }

  void dispose() {
    debugPrint('🔄 Disposing AudioManager (WEB)...');
    _durationTimer?.cancel();
    _playbackTimer?.cancel();
    _audioElement?.pause();
    _recorder.dispose();
    playerController.dispose();
  }
}

class AudioUtils {
  static String formatDuration(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}