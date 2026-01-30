import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';

/// Web version: Modal dialog to input usernames for selected networks
class WebSocialNetworkInputModal extends StatefulWidget {
  final List<NetworkConfig> selectedNetworks;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const WebSocialNetworkInputModal({
    super.key,
    required this.selectedNetworks,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<WebSocialNetworkInputModal> createState() =>
      _WebSocialNetworkInputModalState();
}

class _WebSocialNetworkInputModalState
    extends State<WebSocialNetworkInputModal> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  final Set<String> _connectedOAuthNetworks = {};

  late final List<NetworkConfig> _manualNetworks;
  late final List<NetworkConfig> _oauthNetworks;

  @override
  void initState() {
    super.initState();

    _manualNetworks = widget.selectedNetworks
        .where((n) => n.capability != NetworkAuthCapability.oauth)
        .toList();
    _oauthNetworks = widget.selectedNetworks
        .where((n) => n.capability == NetworkAuthCapability.oauth)
        .toList();

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
    // Same logic as mobile
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

  Future<void> _handleOAuthConnect(NetworkConfig network) async {
    final cubit = context.read<RegisterCubit>();
    final platformName = network.name.toLowerCase();

    debugPrint('🔗 Starting OAuth for $platformName');

    await cubit.startSocialAuth(
      context,
      platformName,
      network.iconPath,
      inEditMode: false,
    );

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

    if (_manualNetworks.isEmpty && _connectedOAuthNetworks.isNotEmpty) {
      widget.onComplete();
      return;
    }

    showProfileLoader(context, message: 'common.loader_sequence.syncing'.tr());

    try {
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, dynamic>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      int successCount = 0;

      for (final network in _manualNetworks) {
        final key = network.name.toLowerCase();
        final username = _controllers[key]?.text.trim() ?? '';

        if (username.isEmpty) continue;

        final platformName = key;
        final baseUrl = _getBaseUrl(network);
        final cleanUsername = username
            .replaceAll('@', '')
            .replaceAll(baseUrl, '')
            .trim();
        final profileUrl = '$baseUrl$cleanUsername';

        final profileData = await cubit.addNetworkByUsername(
          network: platformName,
          usernameOrLink: profileUrl,
          iconPath: network.iconPath,
        );

        if (profileData == null) {
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

        current.removeWhere((e) {
          final existingKey = e.keys.first.toLowerCase();
          return existingKey == platformName;
        });

        current.add({platformName: profileData});
        successCount++;
      }

      if (mounted) Navigator.of(context).pop(); // Close loader

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
      if (mounted) Navigator.of(context).pop(); // Close loader
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      alignment: Alignment.center,
      child: Center(
        child: Container(
          // Made constraint smaller: max width 480 to avoid being "too big"
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B3D), Color(0xFF1A0F2E)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        'addSocials.inputStep.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'addSocials.inputStep.subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // OAuth Section
                      if (_oauthNetworks.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'addSocials.inputStep.oauthSection'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_oauthNetworks.length, (index) {
                          return _buildOAuthButton(_oauthNetworks[index]);
                        }),
                        if (_manualNetworks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // Manual Section
                      if (_manualNetworks.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'addSocials.inputStep.manualSection'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_manualNetworks.length, (index) {
                          return _buildNetworkInput(_manualNetworks[index]);
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

              // Footer with Save Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
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
          Text(
            baseUrl,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
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
        height: 50,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            'buttons.save'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

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
                ? Colors.green.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected
                  ? Colors.green.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(network.iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
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
