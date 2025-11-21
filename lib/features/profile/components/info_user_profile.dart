import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/share_profile.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class InfoUserProfile extends StatefulWidget {
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final String voiceNoteUrl;
  final TutorialKeys? tutorialKeys;
  final bool isOwnProfile;
  final String userId;

  const InfoUserProfile({
    super.key,
    required this.name,
    required this.displayName,
    required this.comunityCount,
    required this.nameComunity,
    required this.voiceNoteUrl,
    this.isOwnProfile = true,
    this.userId = '',
    this.tutorialKeys,
  });

  @override
  State<InfoUserProfile> createState() => _InfoUserProfileState();
}

class _InfoUserProfileState extends State<InfoUserProfile> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Aseguramos que no repita el audio en bucle
    _player.setLoopMode(LoopMode.off);

    // Cuando el audio termina, reiniciamos el estado
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.pause(); // Reinicia al inicio y pausa (al finalizar)
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InfoUserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el voiceNoteUrl, detener y resetear el reproductor
    if (oldWidget.voiceNoteUrl != widget.voiceNoteUrl) {
      _player.stop();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _togglePlay() async {
    final voiceNoteUrl = widget.voiceNoteUrl;
    if (voiceNoteUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("profile.validations.emptyAudio".tr())),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_isPlaying) {
        await _player.pause();
      } else {
        // Solo carga la URL si no está ya cargada o si cambió
        if (_player.audioSource == null ||
            _player.audioSource.toString() != voiceNoteUrl) {
          await _player.setUrl(voiceNoteUrl);
        }
        await _player.play();
      }

      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("profile.validations.errorAudio".tr())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(176, 0, 0, 0).withValues(alpha: 0.05),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ],
          ),
          alignment: Alignment.center,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 150),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.comunityCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.nameComunity,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Botón para reproducir audio
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    key: widget.tutorialKeys?.playButtonKey,
                    onTap: _isLoading ? null : _togglePlay,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                  ),

                  const SizedBox(width: 10),

                  // Compartir perfil - diferencia entre propio y ajeno
                  GestureDetector(
                    key: widget.tutorialKeys?.shareButtonKey,
                    onTap: () {
                      if (widget.isOwnProfile) {
                        // Perfil propio: navegar a la pantalla de QR sin parámetros
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfileQrScreen(),
                          ),
                        );
                      } else {
                        // Perfil ajeno: pasar los datos del usuario para generar su QR
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => ProfileQrScreen(
                              overrideUsername: widget
                                  .userId, // El username del usuario ajeno
                              overrideDisplayName: widget
                                  .name, // El displayName del usuario ajeno
                            ),
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.share,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
