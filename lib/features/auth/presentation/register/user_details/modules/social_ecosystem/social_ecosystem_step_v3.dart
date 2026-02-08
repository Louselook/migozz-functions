import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/add_another_network/mobile/add_another_network.dart';

import 'package:flutter/foundation.dart';
import '../../../../../../../core/components/atomics/network_list.dart';
import '../../../../../../../core/components/formart/text_formart.dart';
import '../../../../../../profile/components/social_rail.dart';
import '../../../../../../profile/presentation/profile/mobile/v3/components/profile_image_mobile_v3.dart';
import '../../../../../../profile/presentation/profile/mobile/v3/components/social_circles_mobile_v3.dart';
import '../../../../../data/domain/models/user/user_dto.dart';
import 'social_network_input_step.dart';
import 'web_add_custom_link_modal.dart';
import 'web_social_ecosystem_modal.dart';
import 'web_social_network_input_modal.dart';

class SocialEcosystemStepV3 extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;
  final UserDTO? user;

  const SocialEcosystemStepV3({
    super.key,
    required this.controller,
    this.user,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<SocialEcosystemStepV3> createState() => _SocialEcosystemStepV3State();
}

class _SocialEcosystemStepV3State extends State<SocialEcosystemStepV3> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Track networks selected for batch adding (not yet connected)
  final Set<String> _pendingSelections = {};

  // Categories for grouping platforms (based on available networks)
  final Map<String, List<String>> _categories = {
    'Social': [
      'instagram',
      'tiktok',
      'youtube',
      'facebook',
      'x',
      'snapchat',
      'pinterest',
      'threads',
      'reddit',
      'linkedin',
    ],
    'Streaming': ['twitch', 'trovo', 'kick'],
    'Music': ['spotify', 'applemusic', 'deezer', 'soundcloud'],
    'Stores': ['shopify', 'woocommerce', 'etsy'],
    'Chat': ['whatsapp', 'telegram', 'discord'],
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
        // Initialize previous count
      });
    }
  }

  void _setupSyncCallback() {
    final registerCubit = context.read<RegisterCubit>();
    final editCubit = context.read<EditCubit>();
    final authCubit = context.read<AuthCubit>();

    debugPrint('🔄 [V3] Setting up sync callback for edit mode');

    registerCubit.onSocialEcosystemUpdated = (newPlatforms) async {
      debugPrint('🔄 [V3] Sync callback triggered!');
      debugPrint('🔄 [V3] New platforms: ${newPlatforms.length}');

      final currentList = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      debugPrint('🔄 [V3] Current list before merge: ${currentList.length}');

      for (final newSocial in newPlatforms) {
        final platform = newSocial.keys.first;
        final existingIndex = currentList.indexWhere(
          (item) => item.keys.first.toLowerCase() == platform.toLowerCase(),
        );

        if (existingIndex != -1) {
          debugPrint('🔄 [V3] Updating $platform');
          currentList[existingIndex] = newSocial;
        } else {
          debugPrint('🔄 [V3] Adding $platform');
          currentList.add(newSocial);
        }
      }

      debugPrint('🔄 [V3] Final list after merge: ${currentList.length}');
      debugPrint('🔄 [V3] Updating EditCubit...');

      editCubit.updateSocialEcosystem(currentList);

      debugPrint('✅ [V3] EditCubit updated successfully');

      // Auto-save immediately after connecting social media
      final userId = authCubit.state.firebaseUser?.uid;
      if (userId != null) {
        debugPrint('💾 [V3] Auto-saving changes...');

        // Show loading dialog
        if (context.mounted) {
          showProfileLoader(
            context,
            type: LoaderType.profileUpdate,
            onCancel: () {},
          );
        }

        try {
          await editCubit.saveAllPendingChanges(userId);
          debugPrint('✅ [V3] Auto-save completed successfully!');

          // Always hide the dialog
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          debugPrint('❌ [V3] Auto-save failed: $e');

          // Always hide the dialog
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'addSocials.messages.errorSave'.tr(
                    namedArgs: {'error': e.toString()},
                  ),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check if a network is pending selection (selected but not connected yet)
  bool _isNetworkPending(NetworkConfig config) {
    final platformName = config.name.toLowerCase();
    return _pendingSelections.contains(platformName);
  }

  /// Toggle pending selection for batch adding
  void _togglePendingSelection(NetworkConfig config) {
    final platformName = config.name.toLowerCase();
    setState(() {
      if (_pendingSelections.contains(platformName)) {
        _pendingSelections.remove(platformName);
      } else {
        _pendingSelections.add(platformName);
      }
    });
  }

  /// Navigate to input step for all pending selections
  void _handleAddPendingNetworks() {
    if (_pendingSelections.isEmpty) return;

    // Get the NetworkConfig for each selected network
    final selectedConfigs = SocialNetworks.enabledNetworks.where((n) {
      final name = n.name.toLowerCase();
      return _pendingSelections.contains(name);
    }).toList();

    if (selectedConfigs.isEmpty) return;

    final registerCubit = context.read<RegisterCubit>();

    // Navigate to input step
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha:0.8),
        builder: (_) => BlocProvider.value(
          value: registerCubit,
          child: WebSocialNetworkInputModal(
            selectedNetworks: selectedConfigs,
            onComplete: () {
              Navigator.of(context).pop();
              setState(() {
                _pendingSelections.clear();
              });
            },
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: registerCubit,
            child: SocialNetworkInputStep(
              selectedNetworks: selectedConfigs,
              onComplete: () {
                // Pop back and clear pending selections
                Navigator.of(context).pop();
                setState(() {
                  _pendingSelections.clear();
                });
              },
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      );
    }
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

  String _categoryLabel(String category) {
    final key = category.toLowerCase();
    return 'addSocials.categories.$key'.tr();
  }

  bool _isNetworkSelected(NetworkConfig config) {
    final selectedList = widget.mode == MoreUserDetailsMode.register
        ? context.watch<RegisterCubit>().state.socialEcosystem ?? []
        : context.watch<EditCubit>().state.socialEcosystem ?? [];

    // Defensive: ensure map not empty before accessing keys.first
    return selectedList.any((e) {
      if (e.isEmpty) return false;
      final platformKey = e.keys.first.toLowerCase();
      return platformKey == config.name.toLowerCase();
    });
  }

  Future<void> _handleSocialTap(NetworkConfig config) async {
    final platformName = config.name.toLowerCase();

    debugPrint('🔵 [_handleSocialTap] Tapped on: $platformName');

    if (widget.mode == MoreUserDetailsMode.register) {
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, dynamic>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      debugPrint('🔵 [Register Mode] Current ecosystem: $current');

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == platformName;
      });

      debugPrint('🔵 [Register Mode] Index found: $index');

      if (index == -1) {
        // Network not connected - toggle pending selection for batch adding
        debugPrint(
          '🔵 [Register Mode] Network not connected, toggling pending selection',
        );
        _togglePendingSelection(config);
      } else {
        debugPrint(
          '🔵 [Register Mode] Network already connected, showing edit dialog',
        );

        // ✅ Check if it's the last network before removing
        if (current.length == 1) {
          CustomSnackbar.show(
            context: context,
            message: 'addSocials.validation.atLeastOne'.tr(),
            type: SnackbarType.warning,
          );
          return;
        }

        final socialData = current[index];
        final remove = await _showEditSocialDialog(config, socialData);
        if (remove == true) {
          debugPrint('🔵 [Register Mode] Removing network at index $index');
          current.removeAt(index);
          cubit.setSocialEcosystem(current);
          debugPrint(
            '🔵 [Register Mode] Network removed, new ecosystem: $current',
          );
        }
      }
    } else {
      final editCubit = context.read<EditCubit>();
      final registerCubit = context.read<RegisterCubit>();

      final current = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      debugPrint('🔵 [Edit Mode] Current ecosystem: $current');

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        debugPrint(
          '🔵 [Edit Mode] Checking platform: $platformKey vs $platformName',
        );
        return platformKey == platformName;
      });

      debugPrint('🔵 [Edit Mode] Index found: $index');

      if (index == -1) {
        debugPrint(
          '🔵 [Edit Mode] Network not connected, opening bottom sheet',
        );
        await registerCubit.startSocialAuth(
          context,
          platformName,
          config.iconPath,
          inEditMode: true,
        );
      } else {
        debugPrint(
          '🔵 [Edit Mode] Network already connected, showing edit dialog',
        );
        final socialData = current[index];
        final remove = await _showEditSocialDialog(config, socialData);
        if (remove == true) {
          debugPrint('🔵 [Edit Mode] Removing network at index $index');
          current.removeAt(index);
          editCubit.updateSocialEcosystem(current);
          debugPrint('🔵 [Edit Mode] Network removed, new ecosystem: $current');

          // Auto-save after removing
          final authCubit = context.read<AuthCubit>();
          final userId = authCubit.state.firebaseUser?.uid;

          if (userId != null) {
            debugPrint('💾 [Edit Mode] Auto-saving after removal...');

            // Show loading dialog
            if (mounted) {
              showProfileLoader(
                context,
                type: LoaderType.profileUpdate,
                onCancel: () {},
              );
            }

            try {
              await editCubit.saveAllPendingChanges(userId);
              debugPrint('✅ [Edit Mode] Auto-save after removal completed!');

              // Always hide the dialog
              if (mounted) Navigator.of(context).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'addSocials.messages.removed'.tr(
                        namedArgs: {'platform': config.displayName},
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ [Edit Mode] Auto-save after removal failed: $e');

              // Always hide the dialog
              if (mounted) Navigator.of(context).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'addSocials.messages.errorRemove'.tr(
                        namedArgs: {'error': e.toString()},
                      ),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  Future<bool?> _showEditSocialDialog(
    NetworkConfig config,
    Map<String, dynamic> socialData,
  ) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B3D), Color(0xFF1A0F2E)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),

                    // Platform icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SvgPicture.asset(
                        config.iconPath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      config.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'addSocials.dialogs.removeQuestion'.tr(
                        namedArgs: {'platform': config.displayName},
                      ),
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Delete button with gradient
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext, true);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'addSocials.dialogs.deleteLink'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'buttons.cancel'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  String _normalizeDomain(String domain) {
    final d = domain.trim().toLowerCase();
    if (d.startsWith('www.')) return d.substring(4);
    return d;
  }

  String _extractUsernameFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return '';
    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (segments.isEmpty) return '';
    var candidate = segments.last.trim();
    if (candidate.startsWith('@')) candidate = candidate.substring(1);
    return candidate;
  }

  List<Map<String, dynamic>> _getRegisterCustomLinks() {
    if (widget.mode != MoreUserDetailsMode.register) return const [];
    final ecosystem =
        context.watch<RegisterCubit>().state.socialEcosystem ?? [];
    final customItems = <Map<String, dynamic>>[];

    for (final entry in ecosystem) {
      // Nuevo schema (plano): {type: 'custom', domain, url, ...}
      final type = entry['type']?.toString().toLowerCase();
      if (type == 'custom') {
        customItems.add(Map<String, dynamic>.from(entry));
        continue;
      }

      // Compatibilidad hacia atrás (schema antiguo): {'custom': {...}}
      if (!entry.containsKey('custom')) continue;
      final data = entry['custom'];
      if (data is Map) {
        customItems.add(Map<String, dynamic>.from(data));
      }
    }
    return customItems;
  }

  Widget _buildCustomLinkRow(Map<String, dynamic> data) {
    final domain = _normalizeDomain(data['domain']?.toString() ?? '');
    final url = data['url']?.toString() ?? '';
    final username = _extractUsernameFromUrl(url);
    final applyIconFromLink = data['applyIconFromLink'] == true;

    // Icono solo si el usuario habilitó la opción.
    final iconUrl = applyIconFromLink
        ? (data['iconUrl']?.toString() ?? _faviconFromDomain(domain))
        : '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (iconUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                iconUrl,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 20, height: 20),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  domain.isEmpty ? 'Link' : domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ahora acepta username nullable y lo maneja defensivamente
  List<SocialLink> _buildSocialLinks(
    List<Map<String, dynamic>>? socialEcosystem,
    String? username,
  ) {
    if (socialEcosystem == null || socialEcosystem.isEmpty) return [];
    final links = <SocialLink>[];
    final cleanUsername = (username ?? '').replaceFirst('@', '').trim();

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
        // custom links don't require username; continue to next social
        continue;
      }

      // If it's not custom and we don't have a username, skip entries
      if (cleanUsername.isEmpty) continue;

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
          final asset = socialInfo['asset'] ?? '';
          final urlStr = socialInfo['url'] ?? '';
          if (asset.isEmpty || urlStr.isEmpty) {
            // skip invalid
            continue;
          }

          links.add(
            SocialLink(
              asset: asset,
              url: Uri.parse(urlStr),
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
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: BlocProvider.value(
            value: context.read<RegisterCubit>(),
            child: WebSocialEcosystemModal(
              mode: widget.mode,
              onContinue: () {
                final registerState = context.read<RegisterCubit>().state;
                final ecosystem = registerState.socialEcosystem ?? [];
                if (ecosystem.isEmpty) {
                  CustomSnackbar.show(
                    context: context,
                    message: 'addSocials.validation.atLeastOne'.tr(),
                    type: SnackbarType.warning,
                  );
                  return;
                }
                widget.controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
      );
    }

    String normalizeUsername(String username) {
      if (username.isEmpty) return '';
      return username.startsWith('@') ? username : '@$username';
    }

    final size = MediaQuery.of(context).size;

    // RAW username depending on mode:
    final rawUsername = widget.mode == MoreUserDetailsMode.edit
        ? (widget.user?.username ?? '')
        : (context.watch<RegisterCubit>().state.username ?? '');

    final username = normalizeUsername(rawUsername);

    // avatar only available in edit mode
    final avatarUrl = widget.mode == MoreUserDetailsMode.edit
        ? widget.user?.avatarUrl
        : null;

    // Get social ecosystem from the appropriate cubit based on mode
    final List<Map<String, dynamic>> socialEcosystem;
    if (widget.mode == MoreUserDetailsMode.register) {
      // RegisterCubit ya usa List<Map<String, dynamic>> (schema unificado)
      socialEcosystem =
          context.watch<RegisterCubit>().state.socialEcosystem ?? [];
    } else {
      // EditCubit already has List<Map<String, dynamic>>
      socialEcosystem = context.watch<EditCubit>().state.socialEcosystem ?? [];
    }

    // Use the safe username variable (NO user! here)
    final socialLinks = _buildSocialLinks(socialEcosystem, rawUsername);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Si estamos en modo registro, validar que haya al menos una red social
        if (widget.mode == MoreUserDetailsMode.register) {
          final socialEcosystem =
              context.read<RegisterCubit>().state.socialEcosystem ?? [];

          if (socialEcosystem.isEmpty) {
            CustomSnackbar.show(
              context: context,
              message: 'addSocials.validation.atLeastOne'.tr(),
              type: SnackbarType.warning,
            );
            return false;
          }
        }

        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.purpleAccent.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.40),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),

                // Only show profile image in edit mode
                if (widget.mode == MoreUserDetailsMode.edit)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0.43 * size.height,
                    child: ProfileImageMobileV3(
                      avatarUrl: avatarUrl,
                      size: size,
                    ),
                  ),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Only show profile info in edit mode
                      if (widget.mode == MoreUserDetailsMode.edit) ...[
                        SizedBox(height: size.height * 0.33),
                        Text(
                          formatDisplayName(
                            widget.user?.displayName,
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
                          username,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 0),
                          child: SocialCirclesMobileV3(links: socialLinks),
                        ),
                        const SizedBox(height: 11),
                      ] else ...[
                        // In register mode, add spacing at top and title
                        const SizedBox(height: 60),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'addSocials.register.title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'addSocials.register.subtitle'.tr(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

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
                            hintText: 'addSocials.search.hint'.tr(),
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

                      // Continue Button - only in register mode
                      if (widget.mode == MoreUserDetailsMode.register)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: _pendingSelections.isNotEmpty
                              ? _buildAddPendingButton()
                              : userDetailsButton(
                                  cubit: context.read<RegisterCubit>(),
                                  controller: widget.controller,
                                  context: context,
                                  action: UserDetailsAction.back,
                                  mode: MoreUserDetailsMode.register,
                                ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child:  GestureDetector(
    onTap: () {
    // En modo registro, enviar código especial si no hay redes
    if (widget.mode == MoreUserDetailsMode.register) {
    final socialEcosystem =
    context
        .read<RegisterCubit>()
        .state
        .socialEcosystem ??
    [];
    if (socialEcosystem.isEmpty) {
    Navigator.pop(context, 'back_no_socials');
    } else {
    Navigator.pop(context, 'done');
    }
    } else {
    Navigator.pop(context);
    }
    },
    child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color: Colors.white.withValues(alpha: 0.2),
    width: 1,
    ),
    ),
    child: const Icon(
    Icons.arrow_back,
    color: Color(0xFFFFFFFF),
    size: 32,
    ),
    ),
    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Button to add pending network selections
  Widget _buildAddPendingButton() {
    return GestureDetector(
      onTap: _handleAddPendingNetworks,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'addSocials.addSelected'.tr(
                  namedArgs: {'count': _pendingSelections.length.toString()},
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
              'addSocials.search.noResults'.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addSocials.search.results'.tr(),
            style: const TextStyle(
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
              childAspectRatio: 2.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
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
    final customLinks = _getRegisterCustomLinks();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        const SizedBox(height: 10),
        ..._categories.entries.map((entry) {
          final categoryName = entry.key;
          final networks = _getNetworksForCategory(categoryName);

          if (networks.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel(categoryName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    final isSelected = _isNetworkSelected(network);
                    return _buildPlatformGridItem(network, isSelected);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }),

        // Add Custom Link Section (alineado con el grid)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'addSocials.customLink.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 1,
                itemBuilder: (context, index) => _buildCustomLinkGridItem(),
              ),

              // Lista de custom links (solo 3 campos: icono opcional, nombre y username)
              if (customLinks.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...customLinks.map(_buildCustomLinkRow),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPlatformGridItem(NetworkConfig network, bool isSelected) {
    // Check if this network is pending selection (only in register mode)
    final isPending =
        widget.mode == MoreUserDetailsMode.register &&
        !isSelected &&
        _isNetworkPending(network);

    // Visual state: connected (isSelected) > pending (isPending) > default
    final isHighlighted = isSelected || isPending;

    return GestureDetector(
      onTap: () => _handleSocialTap(network),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPending
                ? AppColors.primaryPink.withValues(alpha: 0.6)
                : isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final iconSize = (h * 0.44).clamp(20.0, 28.0).toDouble();
            final baseFontSize = (h * 0.33).clamp(12.0, 15.0).toDouble();
            final availableTextWidth =
                constraints.maxWidth - iconSize - 8 - 6 - 6;
            final fitFontSize =
                (availableTextWidth / (network.displayName.length * 0.6))
                    .clamp(10.0, baseFontSize)
                    .toDouble();
            final fontSize = fitFontSize;

            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Show checkmark for pending selections
                if (isPending) ...[
                  Container(
                    width: iconSize * 0.6,
                    height: iconSize * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPink,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: iconSize * 0.4,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                SvgPicture.asset(
                  network.iconPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    network.displayName,
                    style: TextStyle(
                      color: isHighlighted ? Colors.white : Colors.white70,
                      fontSize: fontSize,
                      fontWeight: isHighlighted
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                // Show connected indicator
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: iconSize * 0.7,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomLinkGridItem() {
    return GestureDetector(
      onTap: () async {
        final isRegister = widget.mode == MoreUserDetailsMode.register;

        if (kIsWeb) {
          await showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha:0.8),
            builder: (_) {
              if (isRegister) {
                return BlocProvider.value(
                  value: context.read<RegisterCubit>(),
                  child: WebAddCustomLinkModal(
                    onComplete: () {
                      Navigator.pop(context, 'done');
                    },
                    onBack: () => Navigator.pop(context),
                    isRegister: true,
                  ),
                );
              } else {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<EditCubit>()),
                    BlocProvider.value(value: context.read<AuthCubit>()),
                  ],
                  child: WebAddCustomLinkModal(
                    onComplete: () {
                      Navigator.pop(context, 'done');
                    },
                    onBack: () => Navigator.pop(context),
                    isRegister: false,
                  ),
                );
              }
            },
          ).then((res) {
            // WebAddCustomLinkModal handles saving internally, so we just need to know when it's done.
            // But 'res' might be null if dismissed.
            // We rely on 'onComplete' triggering callback or setState.
            // However, the logic below expects 'result'.
            // We can return 'done' from onComplete pop if we want uniformity.

            // Actually, WebAddCustomLinkModal calls onComplete, inside we pop.
            // We can pass result there.
          });

          // Since WebAddCustomLinkModal saves internally and updates Cubit,
          // we might just need to refresh UI or show snackbar if needed.
          // The code below handles 'result'.
          // Let's adapt.
          return; // Web modal handles its own feedback
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddAnotherNetworkScreen(allowUnauthenticated: isRegister),
          ),
        );

        if (!mounted) return;

        if (isRegister && result is Map) {
          final data = Map<String, dynamic>.from(result);

          final cubit = context.read<RegisterCubit>();
          final current = List<Map<String, dynamic>>.from(
            cubit.state.socialEcosystem ?? [],
          );

          // ✅ Unificar con EDIT: guardar custom como mapa plano
          current.add(data);
          cubit.setSocialEcosystem(current);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('addSocials.customLink.updated'.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        if (result == 'done') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('addSocials.customLink.updated'.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final iconSize = (h * 0.44).clamp(20.0, 28.0).toDouble();
            final baseFontSize = (h * 0.33).clamp(12.0, 15.0).toDouble();
            final availableTextWidth =
                constraints.maxWidth - iconSize - 8 - 6 - 6;
            final label = 'addSocials.customLink.newLabel'.tr();
            final fitFontSize = (availableTextWidth / (label.length * 0.6))
                .clamp(10.0, baseFontSize)
                .toDouble();
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  iconByLabel['Enlace'] ??
                      'assets/icons/social_networks/OtherIconDefault.svg',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: fitFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            );
          },
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
      case 'snapchat':
        url = customUrl ?? 'https://www.snapchat.com/add/$username';
        break;
      case 'threads':
        url = customUrl ?? 'https://www.threads.net/@$username';
        break;
      case 'reddit':
        url = customUrl ?? 'https://www.reddit.com/user/$username';
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
      case 'applemusic':
        url = customUrl ?? 'https://music.apple.com/profile/$username';
        break;
      case 'deezer':
        url = customUrl ?? 'https://www.deezer.com/profile/$username';
        break;
      case 'soundcloud':
        url = customUrl ?? 'https://soundcloud.com/$username';
        break;

      // ==================== WEBSITES & STORES ====================
      case 'website':
      case 'shopify':
      case 'woocommerce':
      case 'etsy':
        url = customUrl ?? '';
        break;

      // ==================== MESSAGING ====================
      case 'whatsapp':
        url = customUrl ?? 'https://wa.me/$username';
        break;
      case 'telegram':
        url = customUrl ?? 'https://t.me/$username';
        break;
      case 'discord':
        url = customUrl ?? '';
        break;

      default:
        url = customUrl ?? '';
    }

    return {'asset': asset, 'url': url};
  }
}
