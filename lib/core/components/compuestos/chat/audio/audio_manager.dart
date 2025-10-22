// pensado para manjar todos los audios

// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_waveforms/audio_waveforms.dart';

// class GlobalAudioManager {
//   static final GlobalAudioManager _instance = GlobalAudioManager._internal();
//   factory GlobalAudioManager() => _instance;
//   GlobalAudioManager._internal();

//   final AudioPlayer _audioPlayer = AudioPlayer();
//   PlayerController? _currentWaveController;
//   String? _currentPlayingUrl;

//   AudioPlayer get audioPlayer => _audioPlayer;

//   Future<void> playAudio({
//     required String url,
//     PlayerController? waveController,
//   }) async {
//     // Si ya está reproduciendo esto, pausar
//     if (_currentPlayingUrl == url && _audioPlayer.playing) {
//       await _audioPlayer.pause();
//       await waveController?.pausePlayer();
//       return;
//     }

//     // Detener reproducción anterior
//     await stopCurrentAudio();

//     // Configurar nuevo audio
//     try {
//       _currentPlayingUrl = url;
//       _currentWaveController = waveController;

//       await _audioPlayer.setUrl(url);
//       await _audioPlayer.play();

//       // Sincronizar waveform si existe
//       if (waveController != null) {
//         // Configurar suscripción para sincronizar posición
//         _audioPlayer.positionStream.listen((position) {
//           try {
//             waveController.seekTo(position.inMilliseconds);
//           } catch (_) {}
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Error reproduciendo audio: $e');
//       _currentPlayingUrl = null;
//       _currentWaveController = null;
//     }
//   }

//   Future<void> stopCurrentAudio() async {
//     try {
//       await _audioPlayer.stop();
//       await _audioPlayer.seek(Duration.zero);

//       if (_currentWaveController != null) {
//         await _currentWaveController?.pausePlayer();
//         await _currentWaveController?.seekTo(0);
//       }
//     } catch (_) {}

//     _currentPlayingUrl = null;
//     _currentWaveController = null;
//   }

//   Future<void> dispose() async {
//     await stopCurrentAudio();
//     await _audioPlayer.dispose();
//   }
// }
