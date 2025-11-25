import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/save_changes_social.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

class SocialEcosystemStep extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;

  const SocialEcosystemStep({
    super.key,
    required this.controller,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<SocialEcosystemStep> createState() => _SocialEcosystemStepState();
}

class _SocialEcosystemStepState extends State<SocialEcosystemStep> {
  @override
  void initState() {
    super.initState();
    _initializeSocialEcosystem();

    // ✅ Configurar sincronización en modo edición
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
        debugPrint(
          '🔹 EditCubit socialEcosystem: ${editState.socialEcosystem}',
        );

        if (editState.socialEcosystem == null ||
            editState.socialEcosystem!.isEmpty) {
          // Si el EditCubit está vacío, cargar desde el AuthCubit
          final authState = context.read<AuthCubit>().state;
          if (authState.userProfile?.socialEcosystem != null) {
            debugPrint(
              '🔹 Cargando desde AuthCubit: ${authState.userProfile!.socialEcosystem}',
            );
            context.read<EditCubit>().updateSocialEcosystem(
              authState.userProfile!.socialEcosystem!,
            );
          }
        }
      });
    }
  }

  // ✅ Nuevo método para configurar callback de sincronización
  void _setupSyncCallback() {
    final registerCubit = context.read<RegisterCubit>();
    final editCubit = context.read<EditCubit>();

    registerCubit.onSocialEcosystemUpdated = (platforms) {
      debugPrint(
        '🔄 [SocialEcosystem] Sincronizando RegisterCubit → EditCubit',
      );
      editCubit.updateSocialEcosystem(platforms);
    };
  }

  @override
  void dispose() {
    // ✅ Limpiar callback al salir
    // if (widget.mode == MoreUserDetailsMode.edit) {
    //   context.read<RegisterCubit>().onSocialEcosystemUpdated = null;
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.mode == MoreUserDetailsMode.edit;
    final editState = isEditMode ? context.watch<EditCubit>().state : null;
    final scaleFactor = context.scaleFactor;
    final deviceType = context.deviceType;

    final horizontalPadding = ResponsiveUtils.scaleValue(
      24.0,
      scaleFactor,
      minValue: 16.0,
      maxValue: 30.0,
    );
    final verticalPadding = ResponsiveUtils.scaleValue(
      16.0,
      scaleFactor,
      minValue: 12.0,
      maxValue: 20.0,
    );
    final topSpacing = ResponsiveUtils.scaleValue(
      16.0,
      scaleFactor,
      minValue: 12.0,
      maxValue: 24.0,
    );
    final contentSpacing = ResponsiveUtils.scaleValue(
      30.0,
      scaleFactor,
      minValue: 15.0,
      maxValue: 20.0,
    );

    final crossAxisCount = ResponsiveUtils.getGridColumns(deviceType);
    final mainAxisSpacing = ResponsiveUtils.scaleValue(
      16.0,
      scaleFactor,
      minValue: 10.0,
      maxValue: 15.0,
    );
    final crossAxisSpacing = ResponsiveUtils.scaleValue(
      16.0,
      scaleFactor,
      minValue: 10.0,
      maxValue: 16.0,
    );

    final availableWidth =
        MediaQuery.of(context).size.width - (horizontalPadding * 2);
    final cardWidth =
        (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final cardSize = Size(cardWidth, cardWidth * 1.1);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: topSpacing),
            PrimaryText(
              widget.mode == MoreUserDetailsMode.register
                  ? "addSocials.register.title".tr()
                  : "addSocials.edit.title".tr(),
            ),
            SecondaryText(
              widget.mode == MoreUserDetailsMode.register
                  ? "addSocials.register.subtitle".tr()
                  : "addSocials.edit.subtitle".tr(),
            ),
            SizedBox(height: contentSpacing),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: deviceType == DeviceType.desktop
                        ? 800.0
                        : deviceType == DeviceType.tablet
                        ? 600.0
                        : double.infinity,
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    itemCount: SocialNetworks.enabledNetworks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: cardSize.width / cardSize.height,
                    ),
                    itemBuilder: (context, index) {
                      final config = SocialNetworks.enabledNetworks[index];
                      final iconSize = cardSize.width * 0.4;
                      final clampedIconSize = iconSize.clamp(24.0, 48.0);

                      // Obtener la lista según el modo
                      final selectedList =
                          widget.mode == MoreUserDetailsMode.register
                          ? context
                                    .watch<RegisterCubit>()
                                    .state
                                    .socialEcosystem ??
                                []
                          : context.watch<EditCubit>().state.socialEcosystem ??
                                [];

                      // Comparar en minúsculas
                      final selected = selectedList.any((e) {
                        final platformKey = e.keys.first.toLowerCase();
                        final labelLower = config.name.toLowerCase();
                        return platformKey == labelLower;
                      });

                      return SocialIconCard(
                        label: config.displayName,
                        assetPath: config.iconPath,
                        iconSize: clampedIconSize,
                        sizeIcon: cardSize,
                        isSelected: selected,
                        onTap: () => _handleSocialTap(config),
                      );
                    },
                  ),
                ),
              ),
            ),

            SizedBox(
              height: ResponsiveUtils.scaleValue(
                16.0,
                scaleFactor,
                minValue: 12.0,
                maxValue: 24.0,
              ),
            ),

            userDetailsButton(
              cubit: context.read<RegisterCubit>(),
              controller: widget.controller,
              context: context,
              // en modo registro: Back, en modo edición: finalRegister (para que ejecute onFinalAction)
              action: isEditMode
                  ? UserDetailsAction.finalRegister
                  : UserDetailsAction.back,
              mode: widget.mode,
              hasChanges: isEditMode ? editState?.hasChanges : null,
              onFinalAction: isEditMode
                  ? () async {
                      final userId = context
                          .read<AuthCubit>()
                          .state
                          .firebaseUser
                          ?.uid;
                      if (userId != null) {
                        await saveSocialChanges(context, userId);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialTap(NetworkConfig config) async {
    if (widget.mode == MoreUserDetailsMode.register) {
      // ========== MODO REGISTRO ==========
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, Map<String, dynamic>>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == config.name.toLowerCase();
      });

      if (index == -1) {
        // Agregar nueva red - Modo registro
        await cubit.startSocialAuth(
          context,
          config.name,
          config.iconPath,
          inEditMode: false,
        );
      } else {
        // Eliminar red existente
        final remove = await _showRemoveDialog(config.displayName);
        if (remove == true) {
          current.removeAt(index);
          cubit.setSocialEcosystem(current);
        }
      }

      debugPrint(
        "🌐 Ecosistema social (registro): ${cubit.state.socialEcosystem}",
      );
    } else {
      // ========== MODO EDICIÓN ==========
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
        // Agregar nueva red - Modo edición
        await registerCubit.startSocialAuth(
          context,
          config.name,
          config.iconPath,
          inEditMode: true,
        );

        debugPrint('🌐 Esperando sincronización de deeplink...');
      } else {
        // Eliminar red existente
        final remove = await _showRemoveDialog(config.displayName);
        if (remove == true) {
          current.removeAt(index);
          editCubit.updateSocialEcosystem(current);
        }
      }

      debugPrint(
        "🌐 Ecosistema social (edición): ${editCubit.state.socialEcosystem}",
      );
    }
  }

  Future<bool?> _showRemoveDialog(String label) {
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
}
