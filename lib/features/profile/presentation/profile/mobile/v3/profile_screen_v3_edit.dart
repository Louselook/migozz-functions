import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_option_button.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_audio.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/profile_strength_indicator.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/bio_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/email_contact_form_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/featured_links_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/contact_info_section.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';

// import '../../../../components/tintes_gradients.dart';
import 'components/profile_image_mobile_v3.dart';
import 'components/social_circles_mobile_v3.dart';

class MobileProfileContentV3Edit extends StatefulWidget {
  final UserDTO user;
  final TutorialKeys tutorialKeys;

  const MobileProfileContentV3Edit({
    super.key,
    required this.user,
    required this.tutorialKeys,
  });

  @override
  State<MobileProfileContentV3Edit> createState() =>
      _MobileProfileContentV3EditState();
}

class _MobileProfileContentV3EditState
    extends State<MobileProfileContentV3Edit> {
      
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Watch AuthCubit to get real-time updates when avatar changes
    final authState = context.watch<AuthCubit>().state;
    final user = authState.userProfile ?? widget.user;

    // Watch EditCubit to get real-time updates when social media is connected
    final editState = context.watch<EditCubit>().state;

    final avatarUrl = user.avatarUrl;
    final bio = user.bio ?? '';

    // Determinar si es el perfil del usuario autenticado
    final currentUserEmail = authState.userProfile?.email ?? '';
    final isOwnProfile = user.email == currentUserEmail;

    // Recuperamos las redes sociales - usar EditCubit si tiene cambios, sino usar user
    final socialEcosystem = editState.socialEcosystem ?? user.socialEcosystem;

    debugPrint('🔍 [ProfileV3Edit] Building social links...');
    debugPrint('🔍 editState.socialEcosystem: ${editState.socialEcosystem}');
    debugPrint('🔍 user.socialEcosystem: ${user.socialEcosystem}');
    debugPrint('🔍 Final socialEcosystem: $socialEcosystem');

    final socialLinks = _buildSocialLinks(socialEcosystem, user.username);
    

    debugPrint('🔍 [ProfileV3Edit] Built ${socialLinks.length} social links');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo / gradiente
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 🧍 Imagen de perfil FIJA
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileImageMobileV3(
              avatarUrl: avatarUrl,
              size: size,
            ),
          ),

          // Back fijo
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                // espacio para la imagen
                SizedBox(height: size.height * 0.44),

                // CONTENEDOR FIJO (sheet)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),

                    // SCROLL INTERNO
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          // Change profile picture
                          GestureDetector(
                            onTap: _uploading ? null : _changeAvatar,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _uploading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _uploading
                                        ? '...'
                                        : 'profile.customization.uploadingProfilePicture.title'
                                            .tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          SocialCirclesMobileV3Edit(
                            links: socialLinks,
                            onAddPressed: () =>
                                _navigateToAddSocial(context),
                          ),

                          const SizedBox(height: 24),
                          ProfileStrengthIndicator(percentage: 80),
                          const SizedBox(height: 17),

                          BioSection(
                            bio: bio,
                            isOwnProfile: isOwnProfile,
                          ),

                          const SizedBox(height: 10),
                          EmailContactFormSection(
                            isOwnProfile: isOwnProfile,
                          ),

                          const SizedBox(height: 10),
                          FeaturedLinksSection(
                            isOwnProfile: isOwnProfile,
                            user: user,
                          ),

                          const SizedBox(height: 10),
                          ContactInfoSection(
                            isOwnProfile: isOwnProfile,
                            user: user,
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                ProfileOptionButton(
                                  icon: Icons.play_circle_outline,
                                  text: 'edit.presentation.record'.tr(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditRecordScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ProfileOptionButton(
                                  icon: Icons.handshake_outlined,
                                  text: 'edit.presentation.interest'.tr(),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditInterestsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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
    );
  }

  /// Change avatar
  Future<void> _changeAvatar() async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId == null) {
      AlertGeneral.show(context, 4, message: 'Error: User not logged in');
      return;
    }

    final editCubit = context.read<EditCubit>();
    setState(() => _uploading = true);

    try {
      await editCubit.changeAvatar(userId);
      if (mounted) {
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

  /// Navigate to social media selection screen V3
  Future<void> _navigateToAddSocial(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId == null) {
      AlertGeneral.show(context, 4, message: 'edit.validations.errorUserLogin'.tr());
      return;
    }

    final editCubit = context.read<EditCubit>();
    editCubit.setEditItem(EditItem.socialEcosystem);

    // Initialize EditCubit with current user data
    final currentSocials = authCubit.state.userProfile?.socialEcosystem ?? [];
    debugPrint(
      '📱 [ProfileV3Edit] Initializing with ${currentSocials.length} social networks',
    );

    editCubit.initializeFromUser(
      socialEcosystem: currentSocials,
      category: authCubit.state.userProfile?.category,
      interests: authCubit.state.userProfile?.interests,
    );

    debugPrint('🔹 Navigating to SocialEcosystemStepV3 in EDIT mode');

    // Navigate to V3 social selection screen
    // Note: RegisterCubit is already provided globally, so we only need to pass EditCubit
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

    // After returning, re-initialize EditCubit with fresh data from AuthCubit
    if (context.mounted) {
      debugPrint('📱 [ProfileV3Edit] Returned from social ecosystem screen');

      // Get the latest user data from AuthCubit
      final updatedUser = authCubit.state.userProfile;
      if (updatedUser != null) {
        debugPrint(
          '📱 [ProfileV3Edit] Re-initializing EditCubit with fresh data',
        );
        debugPrint(
          '📱 [ProfileV3Edit] Fresh socialEcosystem: ${updatedUser.socialEcosystem}',
        );

        // Re-initialize EditCubit with the fresh data from Firestore
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
    debugPrint(
      '🔗 [_buildSocialLinks] Input socialEcosystem: $socialEcosystem',
    );
    debugPrint('🔗 [_buildSocialLinks] Username: $username');

    if (socialEcosystem == null || socialEcosystem.isEmpty) {
      debugPrint(
        '🔗 [_buildSocialLinks] socialEcosystem is null or empty, returning empty list',
      );
      return [];
    }

    final links = <SocialLink>[];
    final cleanUsername = username.replaceFirst('@', '');

    for (final social in socialEcosystem) {
      debugPrint('🔗 [_buildSocialLinks] Processing social: $social');

      for (final entry in social.entries) {
        final platform = entry.key.toLowerCase();
        final data = entry.value;

        debugPrint('🔗 [_buildSocialLinks] Platform: $platform, Data: $data');

        int? followers;
        int? shares;
        String? customUrl;

        if (data is Map<String, dynamic>) {
          followers = _parseIntFromDynamic(data['followers']);
          shares = _parseIntFromDynamic(data['shares']);
          customUrl = data['url']?.toString();
        }

        final socialInfo = _getSocialInfo(platform, cleanUsername, customUrl);
        debugPrint(
          '🔗 [_buildSocialLinks] socialInfo for $platform: $socialInfo',
        );

        if (socialInfo != null) {
          links.add(
            SocialLink(
              asset: socialInfo['asset']!,
              url: Uri.parse(socialInfo['url']!),
              followers: followers,
              shares: shares,
            ),
          );
          debugPrint('✅ [_buildSocialLinks] Added link for $platform');
        } else {
          debugPrint('❌ [_buildSocialLinks] No socialInfo found for $platform');
        }
      }
    }

    debugPrint('🔗 [_buildSocialLinks] Returning ${links.length} links');
    return links;
  }

  int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
        url = customUrl ?? 'https://www.tiktok.com/@$username';
        break;
      case 'instagram':
        url = customUrl ?? 'https://www.instagram.com/$username';
        break;
      case 'x':
      case 'twitter':
        url = customUrl ?? 'https://x.com/$username';
        break;
      case 'facebook':
        url = customUrl ?? 'https://www.facebook.com/$username';
        break;
      case 'pinterest':
        url = customUrl ?? 'https://www.pinterest.com/$username';
        break;
      case 'youtube':
        url = customUrl ?? 'https://www.youtube.com/@$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/$username';
        break;
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/$username';
        break;
      case 'spotify':
        url = customUrl ?? 'https://open.spotify.com/user/$username';
        break;
      case 'linkedin':
        url = customUrl ?? 'https://www.linkedin.com/in/$username';
        break;
      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}


