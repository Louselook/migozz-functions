import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/share_profile.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo para representar una red social con sus seguidores
class SocialNetworkData {
  final String name;
  final int followers;
  final String? iconPath;

  const SocialNetworkData({
    required this.name,
    required this.followers,
    this.iconPath,
  });
}

class InfoUserProfile extends StatefulWidget {
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final String voiceNoteUrl;
  final String? bio;
  final TutorialKeys? tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;
  final bool isOwnProfile;
  final String userId;
  final VoidCallback? onMessageTap;
  final String? contactEmail;
  final String? contactWebsite;

  /// URL para donación (PayPal, etc.)
  final String? donationUrl;

  /// Lista de redes sociales para mostrar en la animación
  final List<SocialNetworkData> socialNetworks;

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
    this.profileTutorialKeys,
    this.onMessageTap,
    this.contactEmail,
    this.contactWebsite,
    this.donationUrl,
    this.socialNetworks = const [],
  });

  @override
  State<InfoUserProfile> createState() => _InfoUserProfileState();
}

class _InfoUserProfileState extends State<InfoUserProfile>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  /// Índice actual para la animación de redes sociales
  /// -1 = community (total), 0+ = índice de red social
  int _currentSocialIndex = -1;

  /// Controlador de animación para el fade
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Configurar animación de fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

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
    _fadeController.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Maneja el tap en community para rotar entre redes sociales
  void _onCommunityTap() {
    if (_isAnimating || widget.socialNetworks.isEmpty) return;

    setState(() => _isAnimating = true);

    // Fade out
    _fadeController.forward().then((_) {
      setState(() {
        // Avanzar al siguiente índice
        if (_currentSocialIndex < widget.socialNetworks.length - 1) {
          _currentSocialIndex++;
        } else {
          _currentSocialIndex = -1; // Volver a community
        }
      });
      // Fade in
      _fadeController.reverse().then((_) {
        setState(() => _isAnimating = false);
      });
    });
  }

  /// Obtiene el contador actual (community o red social específica)
  String _getCurrentCount() {
    if (_currentSocialIndex == -1) {
      return widget.comunityCount;
    }
    return widget.socialNetworks[_currentSocialIndex].followers.toString();
  }

  /// Obtiene el nombre actual (community o nombre de red social)
  String _getCurrentName() {
    if (_currentSocialIndex == -1) {
      return widget.nameComunity;
    }
    return widget.socialNetworks[_currentSocialIndex].name;
  }

  /// Construye el contenido del contador de community/red social
  Widget _buildCommunityContent() {
    final count = _getCurrentCount();
    final name = _getCurrentName();
    final parsedCount = int.tryParse(count) ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatNumber(parsedCount),
          style: const TextStyle(
            color: AppColors.primaryPink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: .7,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
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
      AlertGeneral.show(
        context,
        3,
        message: "profile.validations.emptyAudio".tr(),
      );
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

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

      if (mounted) {
        setState(() => _isPlaying = !_isPlaying);
      }
    } catch (e) {
      if (!mounted) return;
      AlertGeneral.show(
        context,
        4,
        message: "profile.validations.errorAudio".tr(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Construye una línea horizontal para el icono de menú
  Widget _buildMenuLine() {
    return Container(
      width: 12,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  /// Construye el menú de contacto para perfiles de otros usuarios
  Widget _buildContactMenu() {
    // Si no hay datos de contacto, no mostrar nada
    final hasEmail =
        widget.contactEmail != null && widget.contactEmail!.isNotEmpty;
    final hasWebsite =
        widget.contactWebsite != null && widget.contactWebsite!.isNotEmpty;

    if (!hasEmail && !hasWebsite) {
      return const SizedBox(
        width: 22,
      ); // Espacio vacío para mantener alineación
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        // Título del menú
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'profile.contact.title'.tr(args: [widget.name]),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Enviar email
        if (widget.contactEmail != null && widget.contactEmail!.isNotEmpty)
          PopupMenuItem<String>(
            value: 'email',
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.pinkAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  'profile.contact.sendEmail'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        // Visitar sitio web
        if (widget.contactWebsite != null && widget.contactWebsite!.isNotEmpty)
          PopupMenuItem<String>(
            value: 'website',
            child: Row(
              children: [
                Icon(Icons.language, color: Colors.pinkAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  'profile.contact.visitWebsite'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'email':
            if (widget.contactEmail != null) {
              final uri = Uri(scheme: 'mailto', path: widget.contactEmail);
              try {
                // Don't use canLaunchUrl for mailto - it often returns false on Android
                // due to package visibility restrictions. Try launching directly instead.
                await launchUrl(uri);
              } catch (e) {
                debugPrint('Could not launch email: $e');
              }
            }
            break;
          case 'website':
            if (widget.contactWebsite != null) {
              var url = widget.contactWebsite!;
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'https://$url';
              }
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
            break;
        }
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuLine(),
              const SizedBox(height: 3),
              _buildMenuLine(),
              const SizedBox(height: 3),
              _buildMenuLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameHeader() {
    const nameStyle = TextStyle(
      color: Colors.white,
      fontSize: 27,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const contactWidth = 22.0;
        const playSize = 20.0;
        const gap = 8.0;
        const playGap = 12.0;

        final reservedLeft = widget.isOwnProfile ? 0.0 : (contactWidth + gap);
        final reservedRight = playGap + playSize;
        final nameMaxWidth =
            (constraints.maxWidth - reservedLeft - reservedRight)
                .clamp(0.0, constraints.maxWidth)
                .toDouble();

        final painter = TextPainter(
          text: TextSpan(text: widget.name, style: nameStyle),
          textDirection: ui.TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: nameMaxWidth);

        final textWidth = painter.width;
        final centerX = constraints.maxWidth / 2;
        final nameStart = centerX - (textWidth / 2);
        final nameEnd = centerX + (textWidth / 2);

        final contactX = (nameStart - gap - contactWidth)
            .clamp(0.0, constraints.maxWidth - contactWidth)
            .toDouble();
        final playX = (nameEnd + playGap)
            .clamp(0.0, constraints.maxWidth - playSize)
            .toDouble();

        return SizedBox(

          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: nameMaxWidth),
                  child: Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: nameStyle,
                  ),
                ),
              ),
              if (!widget.isOwnProfile)
                Positioned(left: contactX, child: _buildContactMenu()),
              Positioned(
                left: playX,
                child: GestureDetector(
                  key: widget.tutorialKeys?.playButtonKey,
                  onTap: _isLoading ? null : _togglePlay,
                  child: Container(
                    width: playSize,
                    height: playSize,
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nombre + menú de contacto (si no es propio) + botón de play
        Container(
          key: widget.profileTutorialKeys?.nameSectionKey,
          child: _buildNameHeader(),
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
          children: [
            // Lado izquierdo: share icon (ocupa mismo espacio que derecha)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    key:
                        widget.profileTutorialKeys?.shareQrKey ??
                        widget.tutorialKeys?.shareButtonKey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => widget.isOwnProfile
                              ? const ProfileQrScreen()
                              : ProfileQrScreen(
                                  userId: widget.userId,
                                  overrideUsername: widget.displayName
                                      .replaceFirst('@', ''),
                                  overrideDisplayName: widget.name,
                                ),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      AssetsConstants.shareIcon,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),

            // Centro: community counter
            GestureDetector(
              key: widget.profileTutorialKeys?.communityKey,
              onTap: _onCommunityTap,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCommunityContent(),
              ),
            ),

            // Lado derecho: inbox + gift (ocupa mismo espacio que izquierda)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 15),
                  // Ícono de mensaje
                  GestureDetector(
                    key: widget.profileTutorialKeys?.messagesHeaderKey,
                    onTap: widget.onMessageTap,
                    child: Image.asset(
                      AssetsConstants.inboxIcon,
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ícono de donación (regalo)
                  GestureDetector(
                    onTap: () => _showDonationComingSoonDialog(context),
                    child: SvgPicture.asset(
                      'assets/icons/Gift_Icon.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF22C55E),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Bio centrada
        if (widget.bio != null && widget.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
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

  void _showDonationComingSoonDialog(BuildContext context) {
    // Debug para diferenciar si es mi cuenta o de otro usuario
    if (widget.isOwnProfile) {
      debugPrint('💰 [DONATION] Click desde MI CUENTA');
    } else {
      debugPrint('💰 [DONATION] Click desde OTRO USUARIO: ${widget.userId}');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón X para cerrar
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Título
              Text(
                'profile.donation.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje
              Text(
                'profile.donation.message'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
