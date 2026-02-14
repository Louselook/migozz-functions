import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/audio_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/bio_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/contact_info_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/featured_links_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/interests_section.dart';

import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/profile_strength_indicator.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';

import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class WebProfileContentV3Edit extends StatefulWidget {
  final UserDTO user;

  const WebProfileContentV3Edit({super.key, required this.user});

  @override
  State<WebProfileContentV3Edit> createState() =>
      _WebProfileContentV3EditState();
}

class _WebProfileContentV3EditState extends State<WebProfileContentV3Edit> {
  bool _uploading = false;

  // Helper logic copied from MobileProfileContentV3Edit
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

  // Copy helper methods
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
            user: widget.user,
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
            : _faviconFromDomain(domain);
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
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();
        }

        final socialInfo = _getSocialInfo(platform, cleanUsername, customUrl);
        if (socialInfo != null) {
          links.add(
            SocialLink(
              asset: socialInfo['asset']!,
              url: Uri.parse(socialInfo['url']!),
              followers: followers,
              shares: shares,
            ),
          );
        }
      }
    }
    return links;
  }

  int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=\$domain&sz=128';
  }

  Map<String, String>? _getSocialInfo(
    String platform,
    String username,
    String? customUrl,
  ) {
    final normalizedLabel =
        platform[0].toUpperCase() + platform.substring(1).toLowerCase();

    final asset = iconByLabel[normalizedLabel];
    if (asset == null) return null;

    String url;
    switch (platform) {
      case 'tiktok':
        url = customUrl ?? 'https://www.tiktok.com/@\$username';
        break;
      case 'instagram':
        url = customUrl ?? 'https://www.instagram.com/\$username';
        break;
      case 'x':
      case 'twitter':
        url = customUrl ?? 'https://x.com/\$username';
        break;
      case 'facebook':
        url = customUrl ?? 'https://www.facebook.com/\$username';
        break;
      case 'pinterest':
        url = customUrl ?? 'https://www.pinterest.com/\$username';
        break;
      case 'youtube':
        url = customUrl ?? 'https://www.youtube.com/@\$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/\$username';
        break;
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/\$username';
        break;
      case 'spotify':
        url = customUrl ?? 'https://open.spotify.com/user/\$username';
        break;
      case 'linkedin':
        url = customUrl ?? 'https://www.linkedin.com/in/\$username';
        break;
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    // Use Watchers
    final authState = context.watch<AuthCubit>().state;
    final user = authState.userProfile ?? widget.user;
    final editState = context.watch<EditCubit>().state;
    final socialEcosystem = editState.socialEcosystem ?? user.socialEcosystem;
    final socialLinks = _buildSocialLinks(socialEcosystem, user.username);
    final isOwnProfile = user.email == (authState.userProfile?.email ?? '');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: leftMenuWidth), // Spacer for side menu

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Profile Preview
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: Colors.black, // or gradient
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Avatar background
                              if (user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty)
                                Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[900]),
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [Color(0xFF9036c4), Colors.black],
                                      radius: 1.2,
                                    ),
                                  ),
                                ),

                              // Dark Overlay gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Content in Left Panel
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Change Photo Button styled like in mobile/Image 2
                                    GestureDetector(
                                      onTap: _uploading ? null : _changeAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_uploading)
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            else
                                              const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Profile Pic',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Social Circles
                                    SocialCirclesMobileV3Edit(
                                      links: socialLinks,
                                      onAddPressed: () =>
                                          _navigateToAddSocial(context),
                                    ),
                                    const SizedBox(height: 24),

                                    // Progress Bar
                                    ProfileStrengthIndicator(
                                      percentage: _calculateProfileStrength(
                                        user,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),

                              // Back Button
                              Positioned(
                                top: 20,
                                left: 20,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => context.go('/profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Panel: Edit Sections
                      Expanded(
                        flex: 7,
                        child: Container(
                          color: const Color(
                            0xFF0A0A0A,
                          ), // Slightly lighter black for contrast
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BioSection(
                                  bio: user.bio ?? '',
                                  isOwnProfile: isOwnProfile,
                                  profilePercentage: _calculateProfileStrength(
                                    user,
                                  ),
                                  sectionPercentage: _sectionPercentage,
                                  isCompleted: _hasBio(user),
                                ),
                                const SizedBox(height: 24),

                                // EmailContactFormSection(isOwnProfile: isOwnProfile), // Uncomment if needed, was commented in mobile
                                FeaturedLinksSection(
                                  isOwnProfile: isOwnProfile,
                                  user: user,
                                  sectionPercentage: _sectionPercentage,
                                  isCompleted: _hasFeaturedLinks(user),
                                ),
                                const SizedBox(height: 24),

                                ContactInfoSection(
                                  isOwnProfile: isOwnProfile,
                                  user: user,
                                  sectionPercentage: 13,
                                  isCompleted: _hasContactInfo(user),
                                ),
                                const SizedBox(height: 24),

                                AudioSection(
                                  isOwnProfile: isOwnProfile,
                                  voiceNoteUrl: user.voiceNoteUrl,
                                  sectionPercentage: 13,
                                  isCompleted: _hasAudio(user),
                                ),
                                const SizedBox(height: 24),

                                InterestsSection(
                                  isOwnProfile: isOwnProfile,
                                  interests: user.interests,
                                  sectionPercentage: 13,
                                  isCompleted: _hasInterests(user),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side Menu Overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftMenuWidth,
            child: SideMenu(
              tutorialKeys:
                  TutorialKeys(), // Should probably pass this in or create new
              onChatTap: () {}, // Optional
              isChatOpen: false,
              unreadCount: 0, // Should pipe in if needed
            ),
          ),
        ],
      ),
    );
  }
}
