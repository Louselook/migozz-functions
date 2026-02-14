import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/formart/text_formart.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/follow_button.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/modules/share_profile.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo para representar una red social con sus seguidores (web)
class WebSocialNetworkData {
  final String name;
  final int followers;
  final String? iconPath;

  const WebSocialNetworkData({
    required this.name,
    required this.followers,
    this.iconPath,
  });
}

class ProfileInfoPanel extends StatefulWidget {
  final UserDTO user;
  final List<SocialLink> socialLinks;
  final String communityCount;
  final bool isOwnProfile;
  final String? currentUserId;
  final String? targetUserId;

  final int unreadCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  const ProfileInfoPanel({
    super.key,
    required this.user,
    required this.socialLinks,
    required this.communityCount,
    this.isOwnProfile = false,
    this.currentUserId,
    this.targetUserId,
    this.unreadCount = 0,
    this.onNotificationTap,
    this.onMessageTap,
  });

  @override
  State<ProfileInfoPanel> createState() => _ProfileInfoPanelState();
}

class _ProfileInfoPanelState extends State<ProfileInfoPanel>
    with SingleTickerProviderStateMixin {
  // ─── AUDIO ───
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  // ─── COMMUNITY ANIMATION ───
  int _currentSocialIndex = -1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  // ─── APP FOLLOWERS ───
  int _appFollowers = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _player.setLoopMode(LoopMode.off);
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
      }
    });

    _loadAppFollowers();
  }

  Future<void> _loadAppFollowers() async {
    try {
      final followerCubit = context.read<FollowerCubit>();
      final count = widget.isOwnProfile
          ? followerCubit.state.followersCount
          : 0;
      if (mounted && count != _appFollowers) {
        setState(() => _appFollowers = count);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ─── AUDIO PLAYBACK ───

  Future<void> _togglePlay() async {
    final voiceNoteUrl = widget.user.voiceNoteUrl ?? '';
    if (voiceNoteUrl.isEmpty) {
      AlertGeneral.show(
        context,
        3,
        message: 'profile.validations.emptyAudio'.tr(),
      );
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);

      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.audioSource == null ||
            _player.audioSource.toString() != voiceNoteUrl) {
          await _player.setUrl(voiceNoteUrl);
        }
        await _player.play();
      }

      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      if (!mounted) return;
      AlertGeneral.show(
        context,
        4,
        message: 'profile.validations.errorAudio'.tr(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── COMMUNITY TAP ───

  List<WebSocialNetworkData> _buildSocialNetworksData() {
    final data = <WebSocialNetworkData>[
      WebSocialNetworkData(
        name: 'Migozz',
        followers: _appFollowers,
        iconPath: 'assets/icons/social_networks/Other.svg',
      ),
    ];
    return data;
  }

  void _onCommunityTap() {
    final socialNetworks = _buildSocialNetworksData();
    if (_isAnimating || socialNetworks.isEmpty) return;

    setState(() => _isAnimating = true);

    _fadeController.forward().then((_) {
      setState(() {
        if (_currentSocialIndex < socialNetworks.length - 1) {
          _currentSocialIndex++;
        } else {
          _currentSocialIndex = -1;
        }
      });
      _fadeController.reverse().then((_) {
        setState(() => _isAnimating = false);
      });
    });
  }

  String _getCurrentCount() {
    if (_currentSocialIndex == -1) {
      // Total: social followers + app followers
      final socialFollowers = int.tryParse(widget.communityCount) ?? 0;
      final total = socialFollowers + _appFollowers;
      return total.toString();
    }
    final socialNetworks = _buildSocialNetworksData();
    return socialNetworks[_currentSocialIndex].followers.toString();
  }

  String _getCurrentName() {
    if (_currentSocialIndex == -1) {
      return 'profile.presentation.community'.tr();
    }
    final socialNetworks = _buildSocialNetworksData();
    return socialNetworks[_currentSocialIndex].name;
  }

  // ─── SHARE ───

  void _onShareTap() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => widget.isOwnProfile
            ? const ProfileQrScreen()
            : ProfileQrScreen(
                userId: widget.user.email,
                overrideUsername: widget.user.username.replaceFirst('@', ''),
                overrideDisplayName: widget.user.displayName,
              ),
      ),
    );
  }

  // ─── GIFT/DONATION ───

  void _onGiftTap() {
    if (widget.isOwnProfile) {
      debugPrint('💰 [DONATION] Click desde MI CUENTA (web)');
    } else {
      debugPrint(
        '💰 [DONATION] Click desde OTRO USUARIO: ${widget.user.email} (web)',
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogWidth = screenWidth < 600
            ? screenWidth * 0.85
            : screenWidth < 1200
            ? 400.0
            : 420.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                Text(
                  'profile.donation.message'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── MESSAGE ───

  void _onMessageTap() {
    if (widget.onMessageTap != null) {
      widget.onMessageTap!();
    } else {
      // Default: navigate to chats page
      context.go('/chats');
    }
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = widget.user.avatarUrl;
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    const String fallbackAsset = 'assets/images/avatar.webp';

    // Watch FollowerCubit for real-time updates (must be unconditional)
    try {
      final followerState = context.watch<FollowerCubit>().state;
      final newCount = widget.isOwnProfile ? followerState.followersCount : 0;
      if (newCount != _appFollowers) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _appFollowers = newCount);
          }
        });
      }
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- BACKGROUND LAYER ---
          if (hasAvatar)
            Positioned.fill(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      Color(0xFF9036c4),
                      Color(0xFF531175),
                      Color(0xFF1a0526),
                      Colors.black,
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // --- HERO IMAGE LAYER (Fallback only) ---
          if (!hasAvatar)
            Positioned.fill(
              bottom: 150,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Image.asset(fallbackAsset, fit: BoxFit.contain),
                ),
              ),
            ),

          // --- OVERLAY GRADIENT ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 1.0),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // --- CONTENT LAYER ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ─── NAME + VOICE NOTE BUTTON ───
                _buildNameRow(),
                const SizedBox(height: 4),

                // ─── @USERNAME ───
                Text(
                  '@${widget.user.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 11),

                // ─── SHARE + COMMUNITY + SEND + GIFT ROW ───
                _buildCommunityRow(),

                const SizedBox(height: 8),

                // ─── BIO BOX ───
                _buildBioBox(),

                const SizedBox(height: 16),

                // ─── SOCIAL ICONS ROW ───
                SizedBox(
                  height: 40,
                  child: Center(
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.socialLinks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final link = widget.socialLinks[index];
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              link.url,
                              mode: LaunchMode.externalApplication,
                            ),
                            child: SvgPicture.asset(
                              link.asset,
                              width: 32,
                              height: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── BELL ICON TOP LEFT ───
          Positioned(
            top: 40,
            left: 24,
            child: _AnimatedScaleButton(
              onTap: widget.onNotificationTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    63,
                    63,
                    63,
                  ).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 32,
                    ),
                    if (widget.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0050),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              widget.unreadCount > 9
                                  ? '9+'
                                  : widget.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ─── FOLLOW BUTTON (other users) ───
          if (!widget.isOwnProfile &&
              widget.currentUserId != null &&
              widget.targetUserId != null)
            Positioned(
              top: 40,
              right: 24,
              child: FollowButton(
                targetUserId: widget.targetUserId!,
                currentUserId: widget.currentUserId!,
              ),
            ),

          // ─── TOP RIGHT: QR + EDIT (own profile) ───
          if (widget.isOwnProfile)
            Positioned(
              top: 40,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    63,
                    63,
                    63,
                  ).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TopActionButton(
                      icon: Icons.qr_code_2,
                      label: 'QR',
                      onTap: _onShareTap,
                    ),
                    const SizedBox(width: 8),
                    _TopActionButton(
                      icon: Icons.edit_outlined,
                      label: 'edit.presentation.title'.tr(),
                      onTap: () {
                        context.go('/visual-edit');
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── WIDGET BUILDERS ───
  // ═══════════════════════════════════════════════

  /// Name row with play button (like mobile InfoUserProfile)
  Widget _buildNameRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contact menu for other users
          if (!widget.isOwnProfile) ...[
            _buildContactMenu(),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Text(
              widget.user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
          ),

          // Voice note play button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlay,
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              width: 28,
              height: 28,
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
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Community row: share + community counter + send + gift
  Widget _buildCommunityRow() {
    final count = _getCurrentCount();
    final name = _getCurrentName();
    final parsedCount = int.tryParse(count) ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Share icon (left)
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 25),
          child: _AnimatedScaleButton(
            onTap: _onShareTap,
            child: SvgPicture.asset(
              AssetsConstants.shareIcon,
              width: 20,
              height: 20,
            ),
          ),
        ),

        // Community counter (center) with tap animation
        GestureDetector(
          onTap: _onCommunityTap,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
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
            ),
          ),
        ),

        // Send/inbox icon + Gift icon (right)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 15),
            // Inbox/message icon
            _AnimatedScaleButton(
              onTap: _onMessageTap,
              child: Image.asset(
                AssetsConstants.inboxIcon,
                width: 20,
                height: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // Gift icon
            _AnimatedScaleButton(
              onTap: _onGiftTap,
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
      ],
    );
  }

  /// Bio box
  Widget _buildBioBox() {
    final bio = widget.user.bio;
    final hasBio = bio != null && bio.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.greyBackground.withValues(alpha: 0.2),
      ),
      child: hasBio
          ? Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              '00',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
    );
  }

  /// Contact menu for other users' profiles
  Widget _buildContactMenu() {
    final hasEmail =
        widget.user.contactEmail != null &&
        widget.user.contactEmail!.isNotEmpty;
    final hasWebsite =
        widget.user.contactWebsite != null &&
        widget.user.contactWebsite!.isNotEmpty;

    if (!hasEmail && !hasWebsite) {
      return const SizedBox(width: 20);
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'profile.contact.title'.tr(args: [widget.user.displayName]),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (hasEmail)
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
        if (hasWebsite)
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
            if (widget.user.contactEmail != null) {
              final uri = Uri(scheme: 'mailto', path: widget.user.contactEmail);
              try {
                await launchUrl(uri);
              } catch (e) {
                debugPrint('Could not launch email: $e');
              }
            }
            break;
          case 'website':
            if (widget.user.contactWebsite != null) {
              var url = widget.user.contactWebsite!;
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
        width: 20,
        height: 20,
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
}

// ═══════════════════════════════════════════════
// ─── HELPER WIDGETS ───
// ═══════════════════════════════════════════════

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedScaleButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedScaleButton({required this.child, this.onTap});

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
