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
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/profile_strength_indicator.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/bio_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/email_contact_form_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/featured_links_section.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/components/contact_info_section.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

import '../../../../components/tintes_gradients.dart';
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
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;

    final avatarUrl = user.avatarUrl;
    final bio =
        user.bio ??
        'Crafting stories through music.\nNew album "Midnight Reflections" out now 🎶✨';

    // Determinar si es el perfil del usuario autenticado
    final authState = context.watch<AuthCubit>().state;
    final currentUserEmail = authState.userProfile?.email ?? '';
    final isOwnProfile = user.email == currentUserEmail;

    // Recuperamos las redes sociales
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          TintesGradients(child: Container()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileImageMobileV3(avatarUrl: avatarUrl, size: size),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Imagen de perfil con overlay
                SizedBox(height: size.height * 0.4),
                // Botón "Change Profile Picture"
                Container(
                  decoration: BoxDecoration(color: Colors.white10,borderRadius: BorderRadius.circular(5)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 10,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Change Profile Picture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 0),
                  child: SocialCirclesMobileV3Edit(
                    links: socialLinks,
                    onAddPressed: () => _navigateToAddSocial(context),
                  ),
                ),

                const SizedBox(height: 24),

                // Indicador de fortaleza del perfil
                ProfileStrengthIndicator(percentage: 80),

                const SizedBox(height: 17),

                // Sección de Bio
                BioSection(bio: bio, isOwnProfile: isOwnProfile),

                const SizedBox(height: 10),

                // Sección de Email Contact Form
                EmailContactFormSection(isOwnProfile: isOwnProfile),

                const SizedBox(height: 10),

                // Sección de Featured Links
                FeaturedLinksSection(isOwnProfile: isOwnProfile),

                const SizedBox(height: 10),

                // Sección de Contact Info
                ContactInfoSection(isOwnProfile: isOwnProfile, user: user),

                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de retroceso
                  GestureDetector(
                    onTap: () {Navigator.pop(context);},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Botón "Done"
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Co
        ],
      ),
    );
  }

  /// Navigate to social media selection screen V3
  Future<void> _navigateToAddSocial(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final editCubit = context.read<EditCubit>();
    editCubit.setEditItem(EditItem.socialEcosystem);

    // Initialize EditCubit with current user data
    final currentSocials = authCubit.state.userProfile?.socialEcosystem ?? [];
    debugPrint('📱 [ProfileV3Edit] Initializing with ${currentSocials.length} social networks');

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
            mode: MoreUserDetailsMode.edit, user: widget.user,
          ),
        ),
      ),
    );

    // Refresh the UI after returning
    if (context.mounted) {
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
