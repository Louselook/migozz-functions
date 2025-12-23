import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/profile/presentation/add_another_network/mobile/add_another_network.dart';

/// Initial screen for social ecosystem in register mode
/// Shows only the network categories grid without profile info

class SocialEcosystemInitialStep extends StatelessWidget {
  final PageController controller;
  final VoidCallback onAddNetwork;

  const SocialEcosystemInitialStep({
    super.key,
    required this.controller,
    required this.onAddNetwork,
  });

  // Categories for grouping platforms
  final Map<String, List<String>> _categories = const {
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

  bool _isNetworkSelected(BuildContext context, NetworkConfig config) {
    final selectedList =
        context.watch<RegisterCubit>().state.socialEcosystem ?? [];

    return selectedList.any((e) {
      if (e.isEmpty) return false;
      final platformKey = e.keys.first.toLowerCase();
      return platformKey == config.name.toLowerCase();
    });
  }

  Future<void> _handleSocialTap(
    BuildContext context,
    NetworkConfig config,
  ) async {
    final cubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      cubit.state.socialEcosystem ?? [],
    );

    final platformName = config.name.toLowerCase() == 'x'
        ? 'twitter'
        : config.name.toLowerCase();

    final index = current.indexWhere((e) {
      final platformKey = e.keys.first.toLowerCase();
      return platformKey == platformName;
    });

    if (index == -1) {
      // Navigate to full view to add network
      onAddNetwork();
      // Small delay to ensure navigation completes
      await Future.delayed(const Duration(milliseconds: 100));
      // Then trigger the social auth
      if (context.mounted) {
        await cubit.startSocialAuth(
          context,
          platformName,
          config.iconPath,
          inEditMode: false,
        );
      }
    } else {
      // Remove network
      final remove = await _showRemoveDialog(context, config.displayName);
      if (remove == true) {
        current.removeAt(index);
        cubit.setSocialEcosystem(current);
      }
    }
  }

  Future<bool?> _showRemoveDialog(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${"addSocials.popUp.title".tr()} $label?"),
        content: Text("${"addSocials.popUp.subtitle".tr()} $label?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("addSocials.popUp.no".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("addSocials.popUp.yes".tr()),
          ),
        ],
      ),
    );
  }

  void _handleBackTap(BuildContext context) {
    try {
      if (controller.hasClients) {
        final currentPage = (controller.page ?? controller.initialPage).round();
        if (currentPage > 0) {
          controller.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return;
        } else {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
        }
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
      }
    } catch (e, st) {
      debugPrint('[_handleBackTap] error: $e\n$st');
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Gradient background
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

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _handleBackTap(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Title
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

                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'addSocials.register.subtitle'.tr(),
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Categories Grid
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          ..._categories.entries.map((entry) {
                            final categoryName = entry.key;
                            final networks = _getNetworksForCategory(
                              categoryName,
                            );

                            if (networks.isEmpty) {
                              return const SizedBox.shrink();
                            }

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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 2.3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemCount: networks.length,
                                    itemBuilder: (context, index) {
                                      final network = networks[index];
                                      final isSelected = _isNetworkSelected(
                                        context,
                                        network,
                                      );
                                      return _buildPlatformGridItem(
                                        context,
                                        network,
                                        isSelected,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          }),

                          // Add Custom Link Section
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
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 2.3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: 1,
                                  itemBuilder: (context, index) =>
                                      _buildCustomLinkGridItem(context),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: userDetailsButton(
                        cubit: context.read<RegisterCubit>(),
                        controller: controller,
                        context: context,
                        action: UserDetailsAction.back,
                        mode: MoreUserDetailsMode.register,
                      ),
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

  Widget _buildPlatformGridItem(
    BuildContext context,
    NetworkConfig network,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _handleSocialTap(context, network),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
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
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: fontSize,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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

  Widget _buildCustomLinkGridItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnotherNetworkScreen()),
        );
        if (result == 'done' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('addSocials.customLink.updated'.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
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
}
