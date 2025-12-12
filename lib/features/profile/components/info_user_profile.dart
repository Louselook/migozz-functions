import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:migozz_app/core/assets_constants.dart';
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
  final String? bio;
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
    this.bio,
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
            Flexible(
              child: Text(
                formatDisplayName(widget.name, format: FormatName.short),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              key: widget.tutorialKeys?.playButtonKey,
              onTap: _isLoading ? null : _togglePlay,
              child: Container(
                width: 20,
                height: 20,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: .5),
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
              ),
            ),
          ],
        ),

        // DisplayName (@username)
        const SizedBox(height: 3),
        Text(
          widget.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.2),
        ),

        // Contador de comunidad
        const SizedBox(height: 11),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Compartir perfil
            GestureDetector(
              key: widget.tutorialKeys?.shareButtonKey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => widget.isOwnProfile
                        ? const ProfileQrScreen()
                        : ProfileQrScreen(
                            overrideUsername: widget.displayName.replaceFirst(
                              '@',
                              '',
                            ),
                            overrideDisplayName: widget.name,
                          ),
                  ),
                );
              },

              child: SvgPicture.asset(
                AssetsConstants.shareIcon,
                width: 17,
                height: 17,
              ),
            ),

            const SizedBox(width: 25),
            Column(
              children: [
                Text(
                  formatNumber(int.parse(widget.comunityCount)),
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: .7,
                  ),
                ),
                Text(
                  widget.nameComunity,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 25),

            // Ícono de mensaje
            GestureDetector(
              onTap: widget.onMessageTap,
              child: Image.asset(
                AssetsConstants.inboxIcon,
                width: 17,
                height: 17,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (widget.bio != null && widget.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.greyBackground.withValues(alpha: 0.2),
            ),
            child: Text(
              widget.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
