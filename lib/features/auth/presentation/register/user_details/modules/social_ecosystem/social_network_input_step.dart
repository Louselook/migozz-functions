import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';

/// Step 2: Input usernames for all selected networks
class SocialNetworkInputStep extends StatefulWidget {
  final List<NetworkConfig> selectedNetworks;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const SocialNetworkInputStep({
    super.key,
    required this.selectedNetworks,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<SocialNetworkInputStep> createState() => _SocialNetworkInputStepState();
}

class _SocialNetworkInputStepState extends State<SocialNetworkInputStep> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Track which OAuth networks have been connected
  final Set<String> _connectedOAuthNetworks = {};

  // Separate networks by authentication type
  late final List<NetworkConfig> _manualNetworks;
  late final List<NetworkConfig> _oauthNetworks;

  @override
  void initState() {
    super.initState();

    // Separate networks by capability
    _manualNetworks = widget.selectedNetworks
        .where((n) => n.capability != NetworkAuthCapability.oauth)
        .toList();
    _oauthNetworks = widget.selectedNetworks
        .where((n) => n.capability == NetworkAuthCapability.oauth)
        .toList();

    // Create a controller and focus node for each manual network only
    for (final network in _manualNetworks) {
      final key = network.name.toLowerCase();
      _controllers[key] = TextEditingController();
      _focusNodes[key] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getBaseUrl(NetworkConfig network) {
    final name = network.name.toLowerCase();
    switch (name) {
      case 'instagram':
        return 'https://www.instagram.com/';
      case 'tiktok':
        return 'https://www.tiktok.com/@';
      case 'facebook':
        return 'https://www.facebook.com/';
      case 'youtube':
        return 'https://www.youtube.com/@';
      case 'x':
      case 'twitter':
        return 'https://x.com/';
      case 'threads':
        return 'https://www.threads.net/@';
      case 'spotify':
        return 'https://open.spotify.com/user/';
      case 'snapchat':
        return 'https://www.snapchat.com/add/';
      case 'linkedin':
        return 'https://www.linkedin.com/in/';
      case 'twitch':
        return 'https://www.twitch.tv/';
      case 'pinterest':
        return 'https://www.pinterest.com/';
      case 'reddit':
        return 'https://www.reddit.com/user/';
      default:
        return 'https://www.$name.com/';
    }
  }

  bool _validateInputs() {
    // Check if at least one manual input has content OR one OAuth is connected
    bool hasManualInput = false;
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        hasManualInput = true;
        break;
      }
    }
    return hasManualInput || _connectedOAuthNetworks.isNotEmpty;
  }

  /// Handle OAuth network connection
  Future<void> _handleOAuthConnect(NetworkConfig network) async {
    final cubit = context.read<RegisterCubit>();
    final platformName = network.name.toLowerCase() == 'x'
        ? 'twitter'
        : network.name.toLowerCase();

    debugPrint('🔗 Starting OAuth for $platformName');

    await cubit.startSocialAuth(
      context,
      platformName,
      network.iconPath,
      inEditMode: false,
    );

    // Check if it was added successfully
    final ecosystem = cubit.state.socialEcosystem ?? [];
    final wasAdded = ecosystem.any((e) {
      if (e.isEmpty) return false;
      return e.keys.first.toLowerCase() == platformName;
    });

    if (wasAdded && mounted) {
      setState(() {
        _connectedOAuthNetworks.add(platformName);
      });
      CustomSnackbar.show(
        context: context,
        message: 'addSocials.messages.socialConnected'.tr(
          namedArgs: {'platform': network.displayName},
        ),
        type: SnackbarType.success,
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_validateInputs()) {
      CustomSnackbar.show(
        context: context,
        message: 'addSocials.validation.enterAtLeastOne'.tr(),
        type: SnackbarType.warning,
      );
      return;
    }

    // If only OAuth networks were selected and connected, just complete
    if (_manualNetworks.isEmpty && _connectedOAuthNetworks.isNotEmpty) {
      widget.onComplete();
      return;
    }

    // Show custom loader dialog
    showProfileLoader(context, message: 'common.loader_sequence.syncing'.tr());

    try {
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, dynamic>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      int successCount = 0;

      // Process each MANUAL network with input (OAuth already handled)
      for (final network in _manualNetworks) {
        final key = network.name.toLowerCase();
        final username = _controllers[key]?.text.trim() ?? '';

        if (username.isEmpty) continue;

        // Normalize platform name
        final platformName = key == 'x' ? 'twitter' : key;

        // Build the profile URL or username for validation
        final baseUrl = _getBaseUrl(network);
        final cleanUsername = username
            .replaceAll('@', '')
            .replaceAll(baseUrl, '')
            .trim();
        final profileUrl = '$baseUrl$cleanUsername';

        // Validate and get profile using cubit's new method
        final profileData = await cubit.addNetworkByUsername(
          network: platformName,
          usernameOrLink: profileUrl,
          iconPath: network.iconPath,
        );

        if (profileData == null) {
          // Validation failed - show error and continue with others
          if (mounted) {
            CustomSnackbar.show(
              context: context,
              message: 'addSocials.validation.invalidProfile'.tr(
                namedArgs: {'platform': network.displayName},
              ),
              type: SnackbarType.error,
            );
          }
          continue;
        }

        // Remove existing entry for this platform if any
        current.removeWhere((e) {
          final existingKey = e.keys.first.toLowerCase();
          return existingKey == platformName;
        });

        // Add the new entry
        current.add({platformName: profileData});
        successCount++;
      }

      // Close loader dialog
      if (mounted) Navigator.of(context).pop();

      // Save all networks if at least one succeeded
      if (successCount > 0) {
        cubit.setSocialEcosystem(current);

        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: 'addSocials.success.networksAdded'.tr(),
            type: SnackbarType.success,
          );
          widget.onComplete();
        }
      } else if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'addSocials.validation.noValidProfiles'.tr(),
          type: SnackbarType.warning,
        );
      }
    } catch (e) {
      debugPrint('Error saving networks: $e');
      // Close loader dialog on error
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'errors.generic'.tr(),
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onTap: widget.onBack,
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
                    'addSocials.inputStep.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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
                    'addSocials.inputStep.subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Network input fields and OAuth buttons
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // OAuth networks section (buttons to connect)
                      if (_oauthNetworks.isNotEmpty) ...[
                        Text(
                          'addSocials.inputStep.oauthSection'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_oauthNetworks.length, (index) {
                          final network = _oauthNetworks[index];
                          return _buildOAuthButton(network);
                        }),
                        if (_manualNetworks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // Manual networks section (text inputs)
                      if (_manualNetworks.isNotEmpty) ...[
                        Text(
                          'addSocials.inputStep.manualSection'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_manualNetworks.length, (index) {
                          final network = _manualNetworks[index];
                          return _buildNetworkInput(network);
                        }),
                      ],
                    ],
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildSaveButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkInput(NetworkConfig network) {
    final key = network.name.toLowerCase();
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;
    final baseUrl = _getBaseUrl(network);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network label with icon
          Row(
            children: [
              Text(
                'addSocials.inputStep.connectYour'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                network.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Base URL hint
          Text(
            baseUrl,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Network icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: SvgPicture.asset(
                      network.iconPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'addSocials.inputStep.placeholder'.tr(),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      // Focus next field
                      final keys = _focusNodes.keys.toList();
                      final currentIndex = keys.indexOf(key);
                      if (currentIndex < keys.length - 1) {
                        _focusNodes[keys[currentIndex + 1]]?.requestFocus();
                      } else {
                        focusNode.unfocus();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _handleSave,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            'buttons.save'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Build OAuth connect button for a network
  Widget _buildOAuthButton(NetworkConfig network) {
    final platformName = network.name.toLowerCase() == 'x'
        ? 'twitter'
        : network.name.toLowerCase();
    final isConnected = _connectedOAuthNetworks.contains(platformName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isConnected ? null : () => _handleOAuthConnect(network),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Network icon
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(network.iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'addSocials.inputStep.connected'.tr(
                              namedArgs: {'platform': network.displayName},
                            )
                          : 'addSocials.inputStep.connectWith'.tr(
                              namedArgs: {'platform': network.displayName},
                            ),
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isConnected)
                      Text(
                        'addSocials.inputStep.oauthHint'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Status icon
              Icon(
                isConnected ? Icons.check_circle : Icons.login,
                color: isConnected ? Colors.green : AppColors.primaryPink,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
