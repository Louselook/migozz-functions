import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/add_another_network/mobile/add_another_network.dart';

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

  // Track previous state to detect changes
  int _previousSocialCount = 0;

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
        _setupAutoSave(); // Config auto-save from deeplink
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
        _previousSocialCount = editState.socialEcosystem?.length ?? 0;
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
          showProfileLoader(context, message: 'Saving...', onCancel: () {});
        }

        try {
          await editCubit.saveAllPendingChanges(userId);
          debugPrint('✅ [V3] Auto-save completed successfully!');

          // Always hide the dialog
          if (context.mounted) Navigator.of(context).pop();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Social media saved successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ [V3] Auto-save failed: $e');

          // Always hide the dialog
          if (context.mounted) Navigator.of(context).pop();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    };
  }

  // ✅ NUEVO: Configurar listener para auto-save
  void _setupAutoSave() {
    final editCubit = context.read<EditCubit>();
    final authCubit = context.read<AuthCubit>();

    debugPrint('🔄 [V3] Setting up auto-save listener');

    // Listen to EditCubit state changes
    editCubit.stream.listen((editState) async {
      // Check if social ecosystem changed
      final currentCount = editState.socialEcosystem?.length ?? 0;

      if (currentCount != _previousSocialCount && editState.hasChanges) {
        debugPrint('💾 [V3] Detected change in social ecosystem');
        debugPrint('   Previous count: $_previousSocialCount');
        debugPrint('   Current count: $currentCount');

        _previousSocialCount = currentCount;

        // Auto-save
        final userId = authCubit.state.firebaseUser?.uid;
        if (userId != null && mounted) {
          debugPrint('💾 [V3] Auto-saving changes...');

          if (mounted) {
            showProfileLoader(context, message: 'Saving...', onCancel: () {});
          }

          try {
            await editCubit.saveAllPendingChanges(userId);
            debugPrint('✅ [V3] Auto-save completed successfully!');

            if (mounted) Navigator.of(context).pop();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Social media saved successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ [V3] Auto-save failed: $e');

            if (mounted) Navigator.of(context).pop();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    });
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
    debugPrint('🔵 [_handleSocialTap] Tapped on: ${config.name}');

    if (widget.mode == MoreUserDetailsMode.register) {
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, Map<String, dynamic>>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      debugPrint('🔵 [Register Mode] Current ecosystem: $current');

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });

      debugPrint('🔵 [Register Mode] Index found: $index');

      if (index == -1) {
        debugPrint(
          '🔵 [Register Mode] Network not connected, opening bottom sheet',
        );
        await cubit.startSocialAuth(
          context,
          config.name,
          config.iconPath,
          inEditMode: false,
        );
      } else {
        debugPrint(
          '🔵 [Register Mode] Network already connected, showing edit dialog',
        );
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
          '🔵 [Edit Mode] Checking platform: $platformKey vs ${config.name.toLowerCase()}',
        );
        return platformKey == config.name.toLowerCase();
      });

      debugPrint('🔵 [Edit Mode] Index found: $index');

      if (index == -1) {
        debugPrint(
          '🔵 [Edit Mode] Network not connected, opening bottom sheet',
        );
        await registerCubit.startSocialAuth(
          context,
          config.name,
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
                message: 'Removing...',
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
                      '${config.displayName} removed successfully!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
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
                    content: Text('Error removing: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
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
    final TextEditingController usernameController = TextEditingController();

    // Extract username from the social data
    final platformKey = config.name.toLowerCase();
    final data = socialData[platformKey];
    if (data is Map<String, dynamic>) {
      usernameController.text = data['username']?.toString() ?? '';
    }

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
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
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

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
                        'Add ${config.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Username input field
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          hintText: 'Add ${config.displayName} username',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Save button with gradient
                      GestureDetector(
                        onTap: () async {
                          final newUsername = usernameController.text.trim();
                          if (newUsername.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a username'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          // Close the dialog first
                          Navigator.pop(dialogContext, null);

                          // Update the username in the social data
                          if (widget.mode == MoreUserDetailsMode.register) {
                            final cubit = context.read<RegisterCubit>();
                            final current =
                                List<Map<String, Map<String, dynamic>>>.from(
                                  cubit.state.socialEcosystem ?? [],
                                );

                            final index = current.indexWhere((e) {
                              final platformKey = e.keys.first.toLowerCase();
                              return platformKey == config.name.toLowerCase();
                            });

                            if (index != -1) {
                              final platformKey = current[index].keys.first;
                              final platformData = Map<String, dynamic>.from(
                                current[index][platformKey]!,
                              );
                              platformData['username'] = newUsername;
                              current[index] = {platformKey: platformData};
                              cubit.setSocialEcosystem(current);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${config.displayName} username updated!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          } else {
                            // Edit mode
                            final editCubit = context.read<EditCubit>();
                            final current = List<Map<String, dynamic>>.from(
                              editCubit.state.socialEcosystem ?? [],
                            );

                            final index = current.indexWhere((e) {
                              final platformKey = e.keys.first.toLowerCase();
                              return platformKey == config.name.toLowerCase();
                            });

                            if (index != -1) {
                              final platformKey = current[index].keys.first;
                              final platformData = Map<String, dynamic>.from(
                                current[index][platformKey],
                              );
                              platformData['username'] = newUsername;
                              current[index] = {platformKey: platformData};
                              editCubit.updateSocialEcosystem(current);

                              // Auto-save after updating
                              final authCubit = context.read<AuthCubit>();
                              final userId = authCubit.state.firebaseUser?.uid;

                              if (userId != null) {
                                debugPrint(
                                  '💾 [Edit Mode] Auto-saving after username update...',
                                );

                                // Show loading dialog
                                if (context.mounted) {
                                  showProfileLoader(
                                    context,
                                    message: 'Saving...',
                                    onCancel: () {},
                                  );
                                }

                                try {
                                  await editCubit.saveAllPendingChanges(userId);
                                  debugPrint(
                                    '✅ [Edit Mode] Auto-save after update completed!',
                                  );

                                  // Always hide the dialog
                                  if (context.mounted)
                                    Navigator.of(context).pop();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${config.displayName} username updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint(
                                    '❌ [Edit Mode] Auto-save after update failed: $e',
                                  );

                                  // Always hide the dialog
                                  if (context.mounted)
                                    Navigator.of(context).pop();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error saving: $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delete Link button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogContext, true);
                        },
                        child: const Text(
                          'Delete Link',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
      ),
    ).whenComplete(() {
      // Dispose controller after dialog is completely closed
      Future.delayed(const Duration(milliseconds: 300), () {
        usernameController.dispose();
      });
    });
  }

  Future<Map<String, dynamic>?> _showCustomLinkDialog({
    Map<String, dynamic>? existingData,
  }) async {
    final TextEditingController linkController = TextEditingController();
    bool applyIconFromLink = true;
    String? pickedImageUrl;

    if (existingData != null) {
      linkController.text = existingData['url']?.toString() ?? '';
      pickedImageUrl = existingData['iconUrl']?.toString();
      applyIconFromLink =
          pickedImageUrl != null &&
          pickedImageUrl.startsWith('http') &&
          pickedImageUrl.contains('favicon');
    }

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SingleChildScrollView(
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
                  // Close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext, null);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  /**
                   * Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Custom Link Icon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Icon display
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 3,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
                            ),
                          ),
                          child: Center(
                            child: (pickedImageUrl?.isNotEmpty ?? false)
                                ? ClipOval(
                                    child: Image.network(
                                      pickedImageUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.language,
                                              color: Colors.white,
                                              size: 60,
                                            );
                                          },
                                    ),
                                  )
                                : const Icon(
                                    Icons.language,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Link input field
                        TextField(
                          controller: linkController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          onChanged: (value) {
                            if (applyIconFromLink && value.trim().isNotEmpty) {
                              setState(() {
                                pickedImageUrl = _faviconFromDomain(
                                  _domainFromUrl(value.trim()),
                                );
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF7C7480),
                            hintText: 'Add custom Link',
                            hintStyle: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Apply Custom Icon from Link toggle
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Apply Custom Icon from Link',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Switch(
                              value: applyIconFromLink,
                              inactiveTrackColor: const Color(0xFF5E5564),
                              activeTrackColor: const Color(0xFF5E5564),
                              thumbColor: const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  applyIconFromLink = value;
                                  if (value &&
                                      linkController.text.trim().isNotEmpty) {
                                    pickedImageUrl = _faviconFromDomain(
                                      _domainFromUrl(
                                        linkController.text.trim(),
                                      ),
                                    );
                                  } else if (!value) {
                                    pickedImageUrl = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Save button with gradient
                        GestureDetector(
                          onTap: () {
                            final link = linkController.text.trim();
                            if (link.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a link'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final data = <String, dynamic>{
                              'custom': {
                                'type': 'custom',
                                'url': link,
                                if (pickedImageUrl != null)
                                  'iconUrl': pickedImageUrl,
                              },
                            };

                            Navigator.pop(dialogContext, data);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (existingData != null) ...[
                          const SizedBox(height: 16),

                          // Delete Link button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext, {'delete': true});
                            },
                            child: const Text(
                              'Delete Link',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                   */
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        linkController.dispose();
      });
    });
  }

  String _domainFromUrl(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return '';
    }
  }

  String _faviconFromDomain(String domain) {
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
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

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = MediaQuery.of(context).size;
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';
    final avatarUrl = user.avatarUrl;

    // Get social ecosystem from the appropriate cubit based on mode
    final List<Map<String, dynamic>> socialEcosystem;
    if (widget.mode == MoreUserDetailsMode.register) {
      // RegisterCubit has List<Map<String, Map<String, dynamic>>>
      final registerEcosystem =
          context.watch<RegisterCubit>().state.socialEcosystem ?? [];
      // Convert to List<Map<String, dynamic>>
      socialEcosystem = registerEcosystem.cast<Map<String, dynamic>>();
    } else {
      // EditCubit already has List<Map<String, dynamic>>
      socialEcosystem = context.watch<EditCubit>().state.socialEcosystem ?? [];
    }

    final socialLinks = _buildSocialLinks(socialEcosystem, user.username);

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
                    onTap: () async {
                      // Just navigate back - auto-save happens on add/remove
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
                      username,
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

  // ... resto de métodos sin cambios (_buildSearchResults, _buildCategorizedGrid, etc.)

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
              childAspectRatio: 2.3,
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
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.3,
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final iconSize = (h * 0.44).clamp(21.0, 30.0).toDouble();
            final fontSize = (h * 0.34).clamp(14.0, 17.0).toDouble();

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  network.iconPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    network.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: fontSize,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnotherNetworkScreen()),
        );
        if (result == 'done' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom link updated'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
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
