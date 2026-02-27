import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/bio_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/contact_info_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/featured_links_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/interests_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/profile_strength_indicator.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';

/// Visual edit page — accessed from the "Edit" button on the web profile.
/// Contains: avatar change, social circles, profile strength, bio, featured links,
/// contact info, audio section (web restriction), interests.
/// Mirrors mobile profile_screen_v3_edit.dart.
class WebVisualEditPage extends StatefulWidget {
  const WebVisualEditPage({super.key});

  @override
  State<WebVisualEditPage> createState() => _WebVisualEditPageState();
}

class _WebVisualEditPageState extends State<WebVisualEditPage> {
  bool _uploading = false;

  // ─── AVATAR ───

  Future<void> _changeAvatar() async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      AlertGeneral.show(
        context,
        4,
        message: 'edit.validations.errorUserLogin'.tr(),
      );
      return;
    }

    final editCubit = context.read<EditCubit>();
    setState(() => _uploading = true);
    try {
      final wasChanged = await editCubit.changeAvatar(userId, context);
      if (mounted && wasChanged) {
        AlertGeneral.show(
          context,
          1,
          message: 'profile.customization.uploadingProfilePicture.success'.tr(),
        );
      }
    } catch (e) {
      if (mounted) {
        AlertGeneral.show(
          context,
          4,
          message:
              '${'profile.customization.uploadingProfilePicture.error'.tr()}$e',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── SOCIAL ECOSYSTEM ───

  Future<void> _navigateToAddSocial(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      AlertGeneral.show(
        context,
        4,
        message: 'edit.validations.errorUserLogin'.tr(),
      );
      return;
    }

    final editCubit = context.read<EditCubit>();
    editCubit.setEditItem(EditItem.socialEcosystem);

    final currentSocials = authCubit.state.userProfile?.socialEcosystem ?? [];
    editCubit.initializeFromUser(
      socialEcosystem: currentSocials,
      category: authCubit.state.userProfile?.category,
      interests: authCubit.state.userProfile?.interests,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: editCubit),
            BlocProvider.value(value: context.read<RegisterCubit>()),
            BlocProvider.value(value: authCubit),
          ],
          child: SocialEcosystemStepV3(
            controller: PageController(),
            mode: MoreUserDetailsMode.edit,
            user: authCubit.state.userProfile,
          ),
        ),
      ),
    );

    if (context.mounted) {
      final updatedUser = authCubit.state.userProfile;
      if (updatedUser != null) {
        editCubit.initializeFromUser(
          socialEcosystem: updatedUser.socialEcosystem,
          category: updatedUser.category,
          interests: updatedUser.interests,
        );
      }
      setState(() {});
    }
  }

  // ─── PROFILE STRENGTH ───

  static const int _sectionPercentage = 12;

  int _calculateProfileStrength(UserDTO user) {
    int strength = 0;
    if (_hasSocialMedia(user)) strength += _sectionPercentage;
    if (_hasBio(user)) strength += _sectionPercentage;
    if (_hasProfilePicture(user)) strength += _sectionPercentage;
    if (_hasInterests(user)) strength += 13;
    if (_hasCategory(user)) strength += 13;
    if (_hasFeaturedLinks(user)) strength += _sectionPercentage;
    if (_hasContactInfo(user)) strength += 13;
    if (_hasAudio(user)) strength += 13;
    return strength;
  }

  bool _hasSocialMedia(UserDTO user) =>
      user.socialEcosystem != null && user.socialEcosystem!.isNotEmpty;

  bool _hasBio(UserDTO user) => user.bio != null && user.bio!.trim().isNotEmpty;

  bool _hasProfilePicture(UserDTO user) =>
      user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

  bool _hasInterests(UserDTO user) => user.interests.isNotEmpty;

  bool _hasCategory(UserDTO user) =>
      user.category != null && user.category!.isNotEmpty;

  bool _hasFeaturedLinks(UserDTO user) => (user.featuredLinks ?? []).isNotEmpty;

  bool _hasContactInfo(UserDTO user) =>
      (user.contactWebsite != null && user.contactWebsite!.isNotEmpty) ||
      (user.contactPhone != null && user.contactPhone!.isNotEmpty) ||
      (user.contactEmail != null && user.contactEmail!.isNotEmpty);

  bool _hasAudio(UserDTO user) =>
      user.voiceNoteUrl != null && user.voiceNoteUrl!.isNotEmpty;

  // ─── SOCIAL LINKS ───

  List<SocialLink> _buildSocialLinks(
    List<Map<String, dynamic>>? socialEcosystem,
    String username,
  ) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return [];

    final links = <SocialLink>[];
    final cleanUsername = username.replaceFirst('@', '');

    for (final social in socialEcosystem) {
      final type = social['type']?.toString().toLowerCase();
      if (type == 'custom') {
        final url = social['url']?.toString() ?? '';
        final iconUrl = social['iconUrl']?.toString();
        final domain = social['domain']?.toString() ?? '';
        final assetUrl = (iconUrl != null && iconUrl.startsWith('http'))
            ? iconUrl
            : (domain.isNotEmpty
                  ? 'https://www.google.com/s2/favicons?domain=$domain&sz=128'
                  : '');
        if (assetUrl.isNotEmpty && url.isNotEmpty) {
          links.add(
            SocialLink(
              asset: assetUrl,
              url: Uri.parse(url),
              followers: null,
              shares: null,
            ),
          );
        }
        continue;
      }

      for (final entry in social.entries) {
        final platform = entry.key.toLowerCase();
        final data = entry.value;

        int? followers;
        int? shares;
        String? customUrl;

        if (data is Map<String, dynamic>) {
          followers = data['followers'] is int
              ? data['followers']
              : int.tryParse(data['followers']?.toString() ?? '');
          shares = data['shares'] is int
              ? data['shares']
              : int.tryParse(data['shares']?.toString() ?? '');
          customUrl = data['url']?.toString();
        }

        final normalizedLabel =
            platform[0].toUpperCase() + platform.substring(1).toLowerCase();
        final asset = iconByLabel[normalizedLabel];
        if (asset == null) continue;

        String url;
        switch (platform) {
          case 'tiktok':
            url = customUrl ?? 'https://www.tiktok.com/@$cleanUsername';
            break;
          case 'instagram':
            url = customUrl ?? 'https://www.instagram.com/$cleanUsername';
            break;
          case 'x':
          case 'twitter':
            url = customUrl ?? 'https://x.com/$cleanUsername';
            break;
          case 'facebook':
            url = customUrl ?? 'https://www.facebook.com/$cleanUsername';
            break;
          case 'pinterest':
            url = customUrl ?? 'https://www.pinterest.com/$cleanUsername';
            break;
          case 'youtube':
            url = customUrl ?? 'https://www.youtube.com/@$cleanUsername';
            break;
          case 'telegram':
            url = customUrl ?? 'https://t.me/$cleanUsername';
            break;
          case 'whatsapp':
            url = customUrl ?? 'https://wa.me/$cleanUsername';
            break;
          case 'spotify':
            url = customUrl ?? 'https://open.spotify.com/user/$cleanUsername';
            break;
          case 'linkedin':
            url = customUrl ?? 'https://www.linkedin.com/in/$cleanUsername';
            break;
          default:
            url = customUrl ?? '';
        }

        links.add(
          SocialLink(
            asset: asset,
            url: Uri.parse(url),
            followers: followers,
            shares: shares,
          ),
        );
      }
    }

    return links;
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMenuSmall = screenWidth < 600;
    final isMenuMedium = screenWidth >= 600 && screenWidth < 1200;
    final sideMenuWidth = isMenuSmall
        ? 60.0
        : isMenuMedium
        ? 70.0
        : 80.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),

          // SideMenu
          const Positioned(top: 0, bottom: 0, left: 0, child: SideMenu()),

          // Main content
          Positioned(
            top: 0,
            bottom: 0,
            left: sideMenuWidth,
            right: 0,
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState.isLoadingProfile) {
                  return Center(
                    child: LoaderDialog(
                      message: 'edit.presentation.loadingProfile'.tr(),
                    ),
                  );
                }

                final user = authState.userProfile;
                if (user == null) {
                  return Center(
                    child: Text(
                      'edit.presentation.errorUserEmpty'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final editState = context.watch<EditCubit>().state;
                final socialEcosystem =
                    editState.socialEcosystem ?? user.socialEcosystem;
                final socialLinks = _buildSocialLinks(
                  socialEcosystem,
                  user.username,
                );

                final contentWidth = (screenWidth - sideMenuWidth).clamp(
                  400.0,
                  900.0,
                );

                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── BACK + TITLE ───
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.go('/profile'),
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'edit.presentation.title'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ─── HEADER CARD (Avatar + change photo) ───
                          _buildHeaderCard(user),
                          const SizedBox(height: 20),

                          // ─── SOCIAL CIRCLES ───
                          SocialCirclesMobileV3Edit(
                            links: socialLinks,
                            onAddPressed: () => _navigateToAddSocial(context),
                          ),
                          const SizedBox(height: 24),

                          // ─── PROFILE STRENGTH ───
                          ProfileStrengthIndicator(
                            percentage: _calculateProfileStrength(user),
                          ),
                          const SizedBox(height: 24),

                          // ─── BIO SECTION ───
                          BioSection(
                            bio: user.bio ?? '',
                            isOwnProfile: true,
                            profilePercentage: _calculateProfileStrength(user),
                            sectionPercentage: _sectionPercentage,
                            isCompleted: _hasBio(user),
                          ),
                          const SizedBox(height: 12),

                          // ─── FEATURED LINKS ───
                          FeaturedLinksSection(
                            isOwnProfile: true,
                            user: user,
                            sectionPercentage: _sectionPercentage,
                            isCompleted: _hasFeaturedLinks(user),
                          ),
                          const SizedBox(height: 12),

                          // ─── CONTACT INFO ───
                          ContactInfoSection(
                            isOwnProfile: true,
                            user: user,
                            sectionPercentage: 13,
                            isCompleted: _hasContactInfo(user),
                          ),
                          const SizedBox(height: 12),

                          // ─── AUDIO (web restriction) ───
                          _buildAudioSection(user),
                          const SizedBox(height: 12),

                          // ─── INTERESTS ───
                          InterestsSection(
                            isOwnProfile: true,
                            interests: user.interests,
                            sectionPercentage: 13,
                            isCompleted: _hasInterests(user),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── WIDGET BUILDERS ───
  // ═══════════════════════════════════════════════

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.85),
                radius: 0.7,
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.75),
                radius: 0.9,
                colors: [
                  AppColors.primaryPink.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(UserDTO user) {
    final avatarUrl = user.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final handle = user.username.isNotEmpty
        ? (user.username.startsWith('@') ? user.username : '@${user.username}')
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with camera button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.black,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                  child: !hasAvatar
                      ? Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 50,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _uploading ? null : _changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Change photo text
          GestureDetector(
            onTap: _uploading ? null : _changeAvatar,
            child: Text(
              _uploading
                  ? 'profile.customization.uploadingProfilePicture.uploading'
                        .tr()
                  : 'profile.customization.uploadingProfilePicture.title'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            user.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              handle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(UserDTO user) {
    final hasAudio = _hasAudio(user);

    return GestureDetector(
      onTap: () {
        AlertGeneral.show(
          context,
          2,
          message: 'edit.presentation.webRestriction.audio'.tr(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'edit.presentation.record'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '13%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasAudio) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(
                    hasAudio ? Icons.play_circle_outline : Icons.mic_none,
                    color: hasAudio
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hasAudio
                      ? 'edit.editAudio.recorded'.tr()
                      : 'edit.editAudio.noRecording'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
