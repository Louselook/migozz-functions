import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';
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
  final VoidCallback? onMessageTap;

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
    this.onMessageTap,
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
    return Column(
      children: [
        // Nombre + botón de play
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatDisplayName(widget.name, format: FormatName.short),
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
            const SizedBox(width: 8),
            GestureDetector(
              key: widget.tutorialKeys?.playButtonKey,
              onTap: _isLoading ? null : _togglePlay,
              child: _isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
            ),
          ],
        ),

        // DisplayName (@username)
        const SizedBox(height: 2),
        Text(
          widget.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.2,
          ),
        ),

        // Contador de comunidad
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.people_outline, size: 18, color: AppColors.primaryPink),
            // const SizedBox(width: 4),
            Text(
              formatNumber(int.parse(widget.comunityCount)),
              style: const TextStyle(
                color: AppColors.primaryPink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),

        // Share + community name + message
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Compartir perfil
            GestureDetector(
              key: widget.tutorialKeys?.shareButtonKey,
              onTap: () {
                if (widget.isOwnProfile) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const ProfileQrScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ProfileQrScreen(
                        overrideUsername: widget.userId,
                        overrideDisplayName: widget.name,
                      ),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.share_outlined,
                size: 24,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),

            const SizedBox(width: 8),
            Text(
              widget.nameComunity,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),

            // Ícono de mensaje
            GestureDetector(
              onTap: widget.onMessageTap,
              child: Transform.rotate(
                angle: 5.6,
                child: Icon(
                  Icons.send,
                  size: 24,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
