// edit_record_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/core/color.dart';
import 'package:record/record.dart';

class EditRecordScreen extends StatefulWidget {
  const EditRecordScreen({super.key});

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder(); // audio_waveforms
  final AudioPlayer _audioPlayer = AudioPlayer(); // just_audio
  final PlayerController _playerController =
      PlayerController(); // audio_waveforms player

  String? _audioPath;
  bool _isRecording = false;
  bool _isUploading = false;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<Color?> _colorAnim;

  // ✅ Subscripciones para limpiar
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _colorAnim = ColorTween(
      begin: const Color(0xFFFF4DB6),
      end: const Color(0xFFFF8CBF),
    ).animate(_animCtrl);

    // ✅ Sync waveform seeker with audio player's position
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      try {
        _playerController.seekTo(position.inMilliseconds);
      } catch (_) {}
    });

    // ✅ Detectar cuando el audio termina y resetear
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Audio terminó, resetear posición
        _audioPlayer.seek(Duration.zero);
        try {
          _playerController.seekTo(0);
        } catch (_) {}
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<String> _getNewPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecord() async {
    // permiso (AudioRecorder.hasPermission)
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to record denied')),
      );
      return;
    }

    final path = await _getNewPath();

    // start recording. RecordConfig permite opciones (ver audio_waveforms docs)
    await _recorder.start(const RecordConfig(), path: path);

    setState(() {
      _isRecording = true;
      _audioPath = path;
      _seconds = 0;
    });

    _animCtrl.repeat(reverse: true);

    // timer: cuenta y corta en 15s
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _seconds++);
      if (_seconds >= 15) {
        await _stopRecord();
      }
    });
  }

  Future<void> _stopRecord() async {
    if (!_isRecording) return;

    final path = await _recorder.stop(); // devuelve path final
    _timer?.cancel();
    _animCtrl.reverse();

    if (path != null && File(path).existsSync()) {
      try {
        // preparar waveform player
        await _playerController.preparePlayer(
          path: path,
          shouldExtractWaveform: true,
          noOfSamples: 120,
        );
      } catch (e) {
        debugPrint('preparePlayer error: $e');
      }

      try {
        await _audioPlayer.setFilePath(path);
      } catch (e) {
        debugPrint('audioPlayer setFilePath error: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;

    if (_audioPlayer.playing) {
      // ✅ Si está reproduciendo, pausar
      await _audioPlayer.pause();
      try {
        await _playerController.pausePlayer();
      } catch (_) {}
    } else {
      // ✅ Si no está reproduciendo, verificar estado y reproducir
      try {
        // Si está en estado idle o completed, configurar el archivo
        if (_audioPlayer.playerState.processingState == ProcessingState.idle ||
            _audioPlayer.playerState.processingState ==
                ProcessingState.completed) {
          await _audioPlayer.setFilePath(_audioPath!);
        }

        // Reproducir desde el inicio si había terminado
        if (_audioPlayer.position >= (_audioPlayer.duration ?? Duration.zero)) {
          await _audioPlayer.seek(Duration.zero);
          try {
            _playerController.seekTo(0);
          } catch (_) {}
        }

        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }

      try {
        await _playerController.startPlayer();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<String?> _uploadToStorageAndSaveFirestore(String localPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final filename = localPath.split('/').last;
    final storageRef = FirebaseStorage.instance.ref().child(
      'users/${user.uid}/voice/$filename',
    );

    setState(() => _isUploading = true);

    try {
      final uploadTask = storageRef.putFile(File(localPath));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar en Firestore (merge para no sobreescribir)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'voiceNoteUrl': downloadUrl,
        'voiceNoteUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (_audioPath == null || _seconds < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record at least 5 seconds')),
      );
      return;
    }

    // Si hay usuario, intentamos subir y guardar voiceNoteUrl
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snack = ScaffoldMessenger.of(context);
      snack.showSnackBar(const SnackBar(content: Text('Uploading audio...')));

      final url = await _uploadToStorageAndSaveFirestore(_audioPath!);
      if (url != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio uploaded and saved ✅')),
          );
          Navigator.pop(context, url); // regresamos la URL final
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed — try again')),
          );
        }
      }
    } else {
      // no hay usuario: devolvemos la ruta local (o indicar que no se subió)
      Navigator.pop(context, _audioPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Record",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenW * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenH * 0.04),
            const Text(
              "Record Your Voicenote",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Voice note: 5–15 seconds max.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: screenH * 0.05),

            // 🎤 Mic button con pulso neón (hold to record)
            GestureDetector(
              onLongPressStart: (_) => _startRecord(),
              onLongPressEnd: (_) => _stopRecord(),
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, _) {
                  final color = _colorAnim.value ?? const Color(0xFFFF4DB6);
                  return Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 191,
                      height: 191,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.9),
                                  blurRadius: 50,
                                  spreadRadius: 20,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/icons/Mic.svg",
                          width: 140,
                          height: 140,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // contador mientras graba
            if (_isRecording) ...[
              const SizedBox(height: 14),
              Text(
                "${_seconds}s",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            SizedBox(height: screenH * 0.05),

            // 🎧 Player section (wave + play)
            if (_audioPath != null && File(_audioPath!).existsSync())
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Listen to your audio",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4DB6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _audioPlayer.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AudioFileWaveforms(
                            playerController: _playerController,
                            size: const Size(double.infinity, 60),
                            enableSeekGesture: true,
                            playerWaveStyle: const PlayerWaveStyle(
                              fixedWaveColor: Colors.pinkAccent,
                              liveWaveColor: Colors.white,
                              spacing: 4,
                              waveThickness: 2,
                              waveCap: StrokeCap.round,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUploading ? null : _save,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenH * 0.03),
          ],
        ),
      ),
    );
  }
}
