import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
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

  @override
  Widget build(BuildContext context) {
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
                  ? "Your Social Ecosystem"
                  : "Edit Social Ecosystem",
            ),
            SecondaryText(
              widget.mode == MoreUserDetailsMode.register
                  ? "Add your platforms"
                  : "Add or remove platforms",
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
                    itemCount: socials.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: cardSize.width / cardSize.height,
                    ),
                    itemBuilder: (context, index) {
                      final label = socials[index];
                      final assetPath = iconByLabel[label];
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

                      // Comparar en minúsculas (normalizar)
                      final selected = selectedList.any((e) {
                        final platformKey = e.keys.first.toLowerCase();
                        final labelLower = label.toLowerCase();
                        return platformKey == labelLower;
                      });

                      return SocialIconCard(
                        label: label,
                        assetPath: assetPath,
                        iconSize: clampedIconSize,
                        sizeIcon: cardSize,
                        isSelected: selected,
                        onTap: () => _handleSocialTap(label),
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
              action: UserDetailsAction.back,
              mode: widget.mode,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialTap(String label) async {
    if (widget.mode == MoreUserDetailsMode.register) {
      // ========== MODO REGISTRO ==========
      final cubit = context.read<RegisterCubit>();
      final current = List<Map<String, Map<String, dynamic>>>.from(
        cubit.state.socialEcosystem ?? [],
      );

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == label.toLowerCase();
      });

      if (index == -1) {
        // Agregar nueva red - Modo registro
        await cubit.startSocialAuth(
          context,
          label,
          iconByLabel[label]!,
          inEditMode: false, //  IMPORTANTE: Modo registro
        );
      } else {
        // Eliminar red existente
        final remove = await _showRemoveDialog(label);
        if (remove == true) {
          current.removeAt(index);
          cubit.setSocialEcosystem(current);
        }
      }

      debugPrint(
        "🌐 Ecosistema social (registro): ${cubit.state.socialEcosystem}",
      );
    } else {
      final editCubit = context.read<EditCubit>();
      final registerCubit = context.read<RegisterCubit>();

      final current = List<Map<String, dynamic>>.from(
        editCubit.state.socialEcosystem ?? [],
      );

      final index = current.indexWhere((e) {
        final platformKey = e.keys.first.toLowerCase();
        return platformKey == label.toLowerCase();
      });

      if (index == -1) {
        // Agregar nueva red - Modo edición
        // El DeeplinkService sincronizará automáticamente con EditCubit
        await registerCubit.startSocialAuth(
          context,
          label,
          iconByLabel[label]!,
          inEditMode:
              true, //  IMPORTANTE: Modo edición (NO cambia regProgress)
        );

        debugPrint('🌐 Esperando sincronización de deeplink...');
      } else {
        // Eliminar red existente
        final remove = await _showRemoveDialog(label);
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
        title: Text("Desvincular $label?"),
        content: Text("¿Estás seguro que quieres desvincular $label?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }
}
