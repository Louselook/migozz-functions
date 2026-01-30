import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/web_social_network_input_modal.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/web_add_custom_link_modal.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

class WebSocialEcosystemModal extends StatefulWidget {
  final MoreUserDetailsMode mode;
  final VoidCallback? onContinue;

  const WebSocialEcosystemModal({
    super.key,
    this.mode = MoreUserDetailsMode.edit,
    this.onContinue,
  });

  @override
  State<WebSocialEcosystemModal> createState() =>
      _WebSocialEcosystemModalState();
}

class _WebSocialEcosystemModalState extends State<WebSocialEcosystemModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  }

  void _initializeSocialEcosystem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == MoreUserDetailsMode.edit) {
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

  String _categoryLabel(String category) {
    final key = category.toLowerCase();
    return 'addSocials.categories.$key'.tr();
  }

  bool _isNetworkSelected(NetworkConfig config) {
    if (widget.mode == MoreUserDetailsMode.register) {
      final selectedList =
          context.watch<RegisterCubit>().state.socialEcosystem ?? [];
      return selectedList.any((e) {
        if (e.isEmpty) return false;
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });
    } else {
      final selectedList =
          context.watch<EditCubit>().state.socialEcosystem ?? [];
      return selectedList.any((e) {
        if (e.isEmpty) return false;
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });
    }
  }

  Future<void> _handleSocialTap(NetworkConfig config) async {
    final platformName = config.name.toLowerCase();
    List<Map<String, dynamic>> current;
    RegisterCubit? registerCubit;
    EditCubit? editCubit;

    if (widget.mode == MoreUserDetailsMode.register) {
      registerCubit = context.read<RegisterCubit>();
      current = List<Map<String, dynamic>>.from(
        registerCubit.state.socialEcosystem ?? [],
      );
    } else {
      editCubit = context.read<EditCubit>();
      current = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );
    }

    final index = current.indexWhere((e) {
      final platformKey = e.keys.first.toLowerCase();
      return platformKey == platformName;
    });

    if (index == -1) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (context) => BlocProvider.value(
          value: context
              .read<
                RegisterCubit
              >(), // Used by input modal mostly for Auth things, but RegisterCubit has logic too
          child: WebSocialNetworkInputModal(
            selectedNetworks: [config],
            onComplete: () {
              Navigator.pop(context);
              if (widget.mode == MoreUserDetailsMode.edit) {
                _refreshFromAuth();
              }
              // For register, RegisterCubit is updated by input modal directly
            },
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      final socialData = current[index];
      final remove = await _showEditSocialDialog(config, socialData);
      if (remove == true) {
        current.removeAt(index);
        if (widget.mode == MoreUserDetailsMode.register) {
          registerCubit!.setSocialEcosystem(current);
        } else {
          editCubit!.updateSocialEcosystem(current);
          await _saveChanges();
        }
      }
    }
  }

  Future<void> _refreshFromAuth() async {
    final registerState = context.read<RegisterCubit>().state;
    if (registerState.socialEcosystem != null) {
      final newEcosystem = List<Map<String, dynamic>>.from(
        registerState.socialEcosystem!,
      );
      context.read<EditCubit>().updateSocialEcosystem(newEcosystem);
      await _saveChanges();
    }
  }

  Future<void> _saveChanges() async {
    final editCubit = context.read<EditCubit>();
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId != null) {
      try {
        await editCubit.saveAllPendingChanges(userId);
      } catch (e) {
        debugPrint('Auto-save failed: $e');
      }
    }
  }

  List<Map<String, dynamic>> _getCustomLinks() {
    final List<Map<String, dynamic>> ecosystem;
    if (widget.mode == MoreUserDetailsMode.register) {
      ecosystem = context.watch<RegisterCubit>().state.socialEcosystem ?? [];
    } else {
      ecosystem = context.watch<EditCubit>().state.socialEcosystem ?? [];
    }

    final customItems = <Map<String, dynamic>>[];

    for (final entry in ecosystem) {
      final type = entry['type']?.toString().toLowerCase();
      if (type == 'custom') {
        customItems.add(Map<String, dynamic>.from(entry));
        continue;
      }
      if (!entry.containsKey('custom')) continue;
      final data = entry['custom'];
      if (data is Map) {
        customItems.add(Map<String, dynamic>.from(data));
      }
    }
    return customItems;
  }

  Future<bool?> _showEditSocialDialog(
    NetworkConfig config,
    Map<String, dynamic> socialData,
  ) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B3D), Color(0xFF1A0F2E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(config.iconPath),
              ),
              const SizedBox(height: 16),
              Text(
                config.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'addSocials.dialogs.removeQuestion'.tr(
                  namedArgs: {'platform': config.displayName},
                ),
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, false),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'buttons.cancel'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'addSocials.dialogs.deleteLink'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 550,
          height: 700,
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.link, color: AppColors.primaryPink),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'addSocials.register.title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'addSocials.register.subtitle'.tr(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.mode != MoreUserDetailsMode.register)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        splashRadius: 20,
                      ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.white.withOpacity(0.1)),

              // Search
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'addSocials.search.hint'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        _buildSearchResults()
                      else
                        _buildCategorizedGrid(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (widget.mode == MoreUserDetailsMode.register)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onContinue != null) {
                        widget.onContinue!();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'buttons.continue'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final filtered = _getFilteredNetworks();
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'addSocials.search.noResults'.tr(),
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.3, // Matches mobile pill shape
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildPlatformGridItem(filtered[index]);
      },
    );
  }

  Widget _buildCategorizedGrid() {
    final customLinks = _getCustomLinks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._categories.entries.map((entry) {
          final categoryName = entry.key;
          final networks = _getNetworksForCategory(categoryName);
          if (networks.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 8),
                child: Text(
                  _categoryLabel(categoryName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GridView.builder(
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
                  return _buildPlatformGridItem(networks[index]);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }),

        // Custom Link Section
        Text(
          'addSocials.customLink.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 1,
          itemBuilder: (context, index) => _buildCustomLinkGridItem(),
        ),

        if (customLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...customLinks.map(_buildCustomLinkRow),
        ],
      ],
    );
  }

  Widget _buildPlatformGridItem(NetworkConfig network) {
    final isSelected = _isNetworkSelected(network);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleSocialTap(network),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final iconSize = (h * 0.45).clamp(20.0, 24.0).toDouble();

              return Row(
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: SvgPicture.asset(network.iconPath),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      network.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12, // Smaller font for web consistency
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomLinkGridItem() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.8),
            builder: (dialogContext) {
              if (widget.mode == MoreUserDetailsMode.register) {
                return BlocProvider.value(
                  value: context.read<RegisterCubit>(),
                  child: WebAddCustomLinkModal(
                    onComplete: () {
                      Navigator.pop(dialogContext);
                      _refreshFromCustom();
                    },
                    onBack: () => Navigator.pop(dialogContext),
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
                      Navigator.pop(dialogContext);
                      _refreshFromCustom();
                    },
                    onBack: () => Navigator.pop(dialogContext),
                    isRegister: false,
                  ),
                );
              }
            },
          );

          _refreshFromCustom();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final iconSize = (h * 0.45).clamp(20.0, 24.0).toDouble();

              return Row(
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: SvgPicture.asset(
                      'assets/icons/social_networks/OtherIconDefault.svg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'addSocials.customLink.newLabel'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const Icon(Icons.add, color: Colors.white, size: 14),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomLinkRow(Map<String, dynamic> data) {
    // Basic row implementation for custom links
    final domain = data['domain']?.toString() ?? 'Link';
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              domain,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (widget.mode == MoreUserDetailsMode.register) {
                final cubit = context.read<RegisterCubit>();
                final current = List<Map<String, dynamic>>.from(
                  cubit.state.socialEcosystem ?? [],
                );
                current.remove(data);
                cubit.setSocialEcosystem(current);
              } else {
                final editCubit = context.read<EditCubit>();
                final current = List<Map<String, dynamic>>.from(
                  editCubit.state.socialEcosystem ?? [],
                );
                current.remove(data);
                editCubit.updateSocialEcosystem(current);
                await _saveChanges();
              }
            },
            child: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFromCustom() async {
    setState(() {});
    if (widget.mode == MoreUserDetailsMode.edit) {
      final authState = context.read<AuthCubit>().state;
      if (authState.userProfile?.socialEcosystem != null) {
        context.read<EditCubit>().updateSocialEcosystem(
          authState.userProfile!.socialEcosystem!,
        );
      }
    }
  }
}
