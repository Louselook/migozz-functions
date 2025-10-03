import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/utils/responsive_utils.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/social_icon_card.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';

class SocialEcosystemStep extends StatelessWidget {
  final PageController controller;
  const SocialEcosystemStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Usar las utilidades responsive
    final scaleFactor = context.scaleFactor;
    final deviceType = context.deviceType;

    // Calcular paddings y espaciados responsivos usando las utilidades
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

    // Determinar número de columnas según el tipo de dispositivo
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

    // Calcular tamaño disponible para cada card considerando el espacio de la pantalla
    final availableWidth =
        MediaQuery.of(context).size.width - (horizontalPadding * 2);
    final cardWidth =
        (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final cardSize = Size(
      cardWidth,
      cardWidth * 1.1,
    ); // Proporción ligeramente rectangular

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: topSpacing),
            const PrimaryText("Your Social Ecosystem"),
            const SecondaryText("Add your platforms"),
            SizedBox(height: contentSpacing),

            // contenido
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
                    padding: EdgeInsets.symmetric(vertical: 6.0),
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

                      // Obtener la lista seleccionada del cubit
                      final selectedList =
                          context
                              .watch<RegisterCubit>()
                              .state
                              .socialEcosystem ??
                          [];
                      // Para saber si ya está agregada:
                      final selected = selectedList.any(
                        (e) => e.keys.first == label.toLowerCase(),
                      );

                      return SocialIconCard(
                        label: label,
                        assetPath: assetPath,
                        iconSize: clampedIconSize,
                        sizeIcon: cardSize,
                        isSelected: selected,
                        onTap: () async {
                          final cubit = context.read<RegisterCubit>();
                          final current =
                              List<Map<String, Map<String, dynamic>>>.from(
                                cubit.state.socialEcosystem ?? [],
                              );

                          final index = current.indexWhere(
                            (e) => e.keys.first == label.toLowerCase(),
                          );

                          if (index == -1) {
                            // No está vinculado → agregar
                            await cubit.startSocialAuth(
                              context,
                              label,
                              iconByLabel[label]!,
                            );
                            // Nota: startSocialAuth debe agregar automáticamente a socialEcosystem al terminar
                          } else {
                            // Ya está vinculado → confirmar eliminación
                            final remove = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Desvincular $label?"),
                                content: Text(
                                  "¿Estás seguro que quieres desvincular $label?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Sí"),
                                  ),
                                ],
                              ),
                            );

                            if (remove == true) {
                              current.removeAt(index);
                              cubit.setSocialEcosystem(current);
                            }
                          }

                          debugPrint(
                            "🌐 Ecosistema social: ${cubit.state.socialEcosystem}",
                          );
                        },
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

            // Botones
            userDetailsButton(
              controller: controller,
              context: context,
              action: UserDetailsAction.back,
            ),
          ],
        ),
      ),
    );
  }
}
