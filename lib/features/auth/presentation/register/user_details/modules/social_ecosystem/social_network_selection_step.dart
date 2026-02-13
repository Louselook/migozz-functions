import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';

import 'social_network_input_step.dart';
import 'web_social_network_input_modal.dart';

/// Step 1: Select which networks to add (toggle selection only)
class SocialNetworkSelectionStep extends StatefulWidget {
  final PageController controller;
  final VoidCallback onAddOtherNetworks;

  const SocialNetworkSelectionStep({
    super.key,
    required this.controller,
    required this.onAddOtherNetworks,
  });

  @override
  State<SocialNetworkSelectionStep> createState() =>
      _SocialNetworkSelectionStepState();
}

class _SocialNetworkSelectionStepState
    extends State<SocialNetworkSelectionStep> {
  // Track selected networks (just the network names)
  final Set<String> _selectedNetworks = {};

  // Main popular networks to show in the simple list
  final List<String> _mainNetworks = const [
    'instagram',
    'tiktok',
    'facebook',
    'youtube',
  ];

  List<NetworkConfig> _getMainNetworks() {
    return SocialNetworks.enabledNetworks.where((network) {
      return _mainNetworks.contains(network.name.toLowerCase());
    }).toList();
  }

  void _toggleNetwork(String networkName) {
    setState(() {
      if (_selectedNetworks.contains(networkName)) {
        _selectedNetworks.remove(networkName);
      } else {
        _selectedNetworks.add(networkName);
      }
    });
  }

  void _handleContinue() {
    if (_selectedNetworks.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: 'addSocials.validation.selectAtLeastOne'.tr(),
        type: SnackbarType.warning,
      );
      return;
    }

    // Get the NetworkConfig for each selected network
    final selectedConfigs = SocialNetworks.enabledNetworks
        .where((n) => _selectedNetworks.contains(n.name.toLowerCase()))
        .toList();

    final registerCubit = context.read<RegisterCubit>();

    // Navigate to input step
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: registerCubit,
          child: WebSocialNetworkInputModal(
            selectedNetworks: selectedConfigs,
            onComplete: () {
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop('done'); // Pop selection step
            },
            onBack: () {
              Navigator.of(context).pop(); // Just close dialog
            },
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
                // Pop back to this screen and then to chat
                Navigator.of(context).pop(); // Pop input step
                Navigator.of(context).pop('done'); // Pop selection step
              },
              onBack: () {
                Navigator.of(context).pop(); // Just go back to selection
              },
            ),
          ),
        ),
      );
    }
  }

  void _handleBackTap() {
    final cubit = context.read<RegisterCubit>();
    final socialEcosystem = cubit.state.socialEcosystem ?? [];

    if (socialEcosystem.isEmpty) {
      Navigator.of(context).pop('back_no_socials');
      return;
    }

    Navigator.of(context).pop('done');
  }

  @override
  Widget build(BuildContext context) {
    final mainNetworks = _getMainNetworks();

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _handleBackTap();
        return false;
      },
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
                    onTap: _handleBackTap,
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

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'addSocials.selectNetworks.title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'addSocials.selectNetworks.subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          children: [
                            // Main networks
                            ...mainNetworks.map((network) {
                              final isSelected = _selectedNetworks.contains(
                                network.name.toLowerCase(),
                              );
                              return _buildNetworkItem(network, isSelected);
                            }),

                            const SizedBox(height: 8),

                            // Add other networks button
                            _buildAddOtherNetworksButton(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _buildContinueButton(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkItem(NetworkConfig network, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleNetwork(network.name.toLowerCase()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPink.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon box
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(network.iconPath, fit: BoxFit.contain),
              ),

              const SizedBox(width: 16),

              // Network name
              Expanded(
                child: Text(
                  network.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primaryPink
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPink
                        : Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOtherNetworksButton() {
    return GestureDetector(
      onTap: widget.onAddOtherNetworks,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
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

  Widget _buildContinueButton() {
    final hasSelection = _selectedNetworks.isNotEmpty;

    return GestureDetector(
      onTap: _handleContinue,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: hasSelection
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.3),
                    Colors.grey.withValues(alpha: 0.3),
                  ],
                ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            'buttons.continue'.tr(),
            style: TextStyle(
              color: hasSelection
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
