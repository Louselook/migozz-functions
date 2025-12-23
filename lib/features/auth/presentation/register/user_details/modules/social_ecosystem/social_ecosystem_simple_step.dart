import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';

/// Simple list view of main social networks - First screen in register mode
class SocialEcosystemSimpleStep extends StatelessWidget {
  final PageController controller;
  final VoidCallback onAddOtherNetworks;

  const SocialEcosystemSimpleStep({
    super.key,
    required this.controller,
    required this.onAddOtherNetworks,
  });

  // Main popular networks to show in the simple list
  final List<String> _mainNetworks = const [
    'instagram',
    'tiktok',
    'facebook',
    'youtube',
    'x',
  ];

  List<NetworkConfig> _getMainNetworks() {
    return SocialNetworks.enabledNetworks.where((network) {
      return _mainNetworks.contains(network.name.toLowerCase());
    }).toList();
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
      // Add network
      await cubit.startSocialAuth(
        context,
        platformName,
        config.iconPath,
        inEditMode: false,
      );
    } else {
      // Remove network - but check if it's the last one
      if (current.length == 1) {
        CustomSnackbar.show(
          context: context,
          message: 'addSocials.validation.atLeastOne'.tr(),
          type: SnackbarType.warning,
        );
        return;
      }

      final remove = await _showRemoveDialog(context, config);
      if (remove == true) {
        current.removeAt(index);
        cubit.setSocialEcosystem(current);
      }
    }
  }

  Future<bool?> _showRemoveDialog(BuildContext context, NetworkConfig config) {
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

  void _handleBackTap(BuildContext context) {
    // ✅ Validate at least one network is added in register mode
    final cubit = context.read<RegisterCubit>();
    final socialEcosystem = cubit.state.socialEcosystem ?? [];

    if (socialEcosystem.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: 'addSocials.validation.atLeastOne'.tr(),
        type: SnackbarType.warning,
      );
      return;
    }

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
    final mainNetworks = _getMainNetworks();

    return SafeArea(
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
            Column(
              children: [
                const SizedBox(height: 100),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          const SizedBox(height: 8),

                          // Main networks
                          ...mainNetworks.map((network) {
                            final isSelected = _isNetworkSelected(
                              context,
                              network,
                            );
                            return _buildNetworkItem(
                              context,
                              network,
                              isSelected,
                            );
                          }),

                          const SizedBox(height: 8),

                          // Add other networks button
                          _buildAddOtherNetworksButton(context),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Continue Button with validation
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _buildContinueButton(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ✅ Validate at least one network before continuing
        final cubit = context.read<RegisterCubit>();
        final socialEcosystem = cubit.state.socialEcosystem ?? [];

        if (socialEcosystem.isEmpty) {
          CustomSnackbar.show(
            context: context,
            message: 'addSocials.validation.atLeastOne'.tr(),
            type: SnackbarType.warning,
          );
          return;
        }

        // If validation passes, use the normal button behavior
        if (controller.hasClients) {
          final currentPage = (controller.page ?? controller.initialPage)
              .round();
          if (currentPage < 1) {
            controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
      child: userDetailsButton(
        cubit: context.read<RegisterCubit>(),
        controller: controller,
        context: context,
        action: UserDetailsAction.back,
        mode: MoreUserDetailsMode.register,
      ),
    );
  }

  Widget _buildNetworkItem(
    BuildContext context,
    NetworkConfig network,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _handleSocialTap(context, network),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon box
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset(
                    network.iconPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Network name
              Expanded(
                child: Text(
                  network.displayName,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              // Checkmark if selected
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryPink,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOtherNetworksButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddOtherNetworks,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Pink circular + icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'addSocials.addOtherNetworks'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
