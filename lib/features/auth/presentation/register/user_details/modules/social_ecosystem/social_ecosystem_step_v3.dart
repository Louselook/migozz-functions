import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

import '../../../../../../../core/components/atomics/network_list.dart';
import '../../../../../../../core/components/formart/text_formart.dart';
import '../../../../../../profile/components/social_rail.dart';
import '../../../../../../profile/presentation/profile/mobile/v3/components/profile_image_mobile_v3.dart';
import '../../../../../../profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';
import '../../../../../data/domain/models/user/user_dto.dart';

class SocialEcosystemStepV3 extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;
  final UserDTO user;

  const SocialEcosystemStepV3({
    super.key,
    required this.controller,
    required this.user,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<SocialEcosystemStepV3> createState() => _SocialEcosystemStepV3State();
}

class _SocialEcosystemStepV3State extends State<SocialEcosystemStepV3> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Categories for grouping platforms (based on available networks)
  final Map<String, List<String>> _categories = {
    'Social': ['instagram', 'tiktok', 'facebook', 'twitter', 'linkedin'],
    'Streaming': ['twitch', 'kick', 'youtube'],
    'Music': ['spotify'],
    'Websites & Stores': ['website', 'shopify', 'woocommerce', 'etsy'],
    'Messaging': ['whatsapp', 'telegram'],
  };

  @override
  void initState() {
    super.initState();
    _initializeSocialEcosystem();

    if (widget.mode == MoreUserDetailsMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupSyncCallback();
      });
    }
  }

  void _initializeSocialEcosystem() {
    if (widget.mode == MoreUserDetailsMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final editState = context.read<EditCubit>().state;
        if (editState.socialEcosystem == null ||
            editState.socialEcosystem!.isEmpty) {
          final authState = context.read<AuthCubit>().state;
          if (authState.userProfile?.socialEcosystem != null) {
            context.read<EditCubit>().updateSocialEcosystem(
              authState.userProfile!.socialEcosystem!,
            );
          }
        }
      });
    }
  }

  void _setupSyncCallback() {
    final registerCubit = context.read<RegisterCubit>();
    final editCubit = context.read<EditCubit>();

    registerCubit.onSocialEcosystemUpdated = (newPlatforms) {
      final currentList = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      for (final newSocial in newPlatforms) {
        final platform = newSocial.keys.first;
        final existingIndex = currentList.indexWhere(
          (item) => item.keys.first.toLowerCase() == platform.toLowerCase(),
        );

        if (existingIndex != -1) {
          currentList[existingIndex] = newSocial;
        } else {
          currentList.add(newSocial);
        }
      }

      editCubit.updateSocialEcosystem(currentList);
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NetworkConfig> _getFilteredNetworks() {
    final allNetworks = SocialNetworks.enabledNetworks;
    if (_searchQuery.isEmpty) {
      return allNetworks;
    }
    return allNetworks.where((network) {
      return network.displayName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  List<NetworkConfig> _getNetworksForCategory(String category) {
    final categoryNetworks = _categories[category] ?? [];
    return SocialNetworks.enabledNetworks.where((network) {
      return categoryNetworks.contains(network.name.toLowerCase());
    }).toList();
  }

  bool _isNetworkSelected(NetworkConfig config) {
    final selectedList = widget.mode == MoreUserDetailsMode.register
        ? context.watch<RegisterCubit>().state.socialEcosystem ?? []
        : context.watch<EditCubit>().state.socialEcosystem ?? [];

    return selectedList.any((e) {
      final platformKey = e.keys.first.toLowerCase();
      return platformKey == config.name.toLowerCase();
    });
  }

  Future<void> _handleSocialTap(NetworkConfig config) async {
    if (widget.mode == MoreUserDetailsMode.register) {
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, Map<String, dynamic>>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });

      if (index == -1) {
        await cubit.startSocialAuth(
          context,
          config.name,
          config.iconPath,
          inEditMode: false,
        );
      } else {
        final remove = await _showRemoveDialog(config.displayName);
        if (remove == true) {
          current.removeAt(index);
          cubit.setSocialEcosystem(current);
        }
      }
    } else {
      final editCubit = context.read<EditCubit>();
      final registerCubit = context.read<RegisterCubit>();

      final current = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });

      if (index == -1) {
        await registerCubit.startSocialAuth(
          context,
          config.name,
          config.iconPath,
          inEditMode: true,
        );
      } else {
        final remove = await _showRemoveDialog(config.displayName);
        if (remove == true) {
          current.removeAt(index);
          editCubit.updateSocialEcosystem(current);
        }
      }
    }
  }

  Future<bool?> _showRemoveDialog(String platformName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Remove Platform',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to remove $platformName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';
    final avatarUrl = user.avatarUrl;
    final socialLinks = _buildSocialLinks(user.socialEcosystem, user.username);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background gradients matching V3 profile
              TintesGradients(child: Container()),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ProfileImageMobileV3(avatarUrl: avatarUrl, size: size),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,

                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              // Co
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.33),
                    Text(
                      formatDisplayName(
                        widget.user.displayName,
                        format: FormatName.short,
                      ),
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

                    // DisplayName (@username)
                    const SizedBox(height: 3),
                    Text(
                      "${username}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 0),
                      child: SocialCirclesMobileV3(links: socialLinks),
                    ),
                    // Contador de comunidad
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          isDense: true, // decrease height
                          filled: true,
                          fillColor: AppColors.greyBackground.withValues(
                            alpha: 0.4,
                          ),

                          hintText: 'Search For Platforms',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),

                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),

                          // Rounded corners
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5, // lower vertical padding
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),

                    // Content
                    Expanded(
                      child: _searchQuery.isNotEmpty
                          ? _buildSearchResults()
                          : _buildCategorizedGrid(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final filteredNetworks = _getFilteredNetworks();

    if (filteredNetworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No platforms found',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(10),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredNetworks.length,
            itemBuilder: (context, index) {
              final network = filteredNetworks[index];
              final isSelected = _isNetworkSelected(network);

              return _buildPlatformGridItem(network, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedGrid() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        const SizedBox(height: 10),

        ..._categories.entries.map((entry) {
          final categoryName = entry.key;
          final networks = _getNetworksForCategory(categoryName);

          if (networks.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(10),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    final isSelected = _isNetworkSelected(network);
                    return _buildPlatformGridItem(network, isSelected);
                  },
                ),
              ],
            ),
          );
        }),

        // Add Custom Link Section
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Custom Link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildCustomLinkGridItem(),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPlatformGridItem(NetworkConfig network, bool isSelected) {
    return GestureDetector(
      onTap: () => _handleSocialTap(network),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white10
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryPink.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Platform Icon
            SvgPicture.asset(
              network.iconPath,
              width: 17,
              height: 17,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 5),

            // Platform Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                network.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLinkGridItem() {
    return GestureDetector(
      onTap: () {
        // Handle custom link addition
        debugPrint('Add custom link tapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            '+Add Custom Link',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
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
      // ==================== SOCIAL MEDIA ====================
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
      case 'linkedin':
        url = customUrl ?? 'https://www.linkedin.com/in/$username';
        break;

      // ==================== STREAMING ====================
      case 'twitch':
        url = customUrl ?? 'https://www.twitch.tv/$username';
        break;
      case 'kick':
        url = customUrl ?? 'https://kick.com/$username';
        break;
      case 'trovo':
        url = customUrl ?? 'https://trovo.live/s/$username';
        break;

      // ==================== MUSIC ====================
      case 'spotify':
        url = customUrl ?? 'https://open.spotify.com/user/$username';
        break;

      // ==================== WEBSITES & STORES ====================
      case 'website':
      case 'shopify':
      case 'woocommerce':
      case 'etsy':
        // Para estos, el customUrl es obligatorio (viene del servicio directo)
        url = customUrl ?? '';
        break;

      // ==================== MESSAGING ====================
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/$username';
        break;

      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}
