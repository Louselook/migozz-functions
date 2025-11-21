import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

/// Selector de versión de perfil (1, 2 o 3)
/// Permite al usuario elegir qué diseño de perfil prefiere
class ProfileVersionSelector extends StatefulWidget {
  final int currentVersion;

  const ProfileVersionSelector({super.key, required this.currentVersion});

  @override
  State<ProfileVersionSelector> createState() => _ProfileVersionSelectorState();
}

class _ProfileVersionSelectorState extends State<ProfileVersionSelector> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              "profile.design.title".tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "profile.design.subtitle".tr(),
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Opciones de versión
            _VersionOption(
              version: 1,
              title: "profile.design.versions.classic.name".tr(),
              description: "profile.design.versions.classic.description".tr(),
              isSelected: widget.currentVersion == 1,
              onTap: () => _selectVersion(context, 1),
            ),
            const SizedBox(height: 16),
            _VersionOption(
              version: 2,
              title: "profile.design.versions.modern.name".tr(),
              description: "profile.design.versions.modern.description".tr(),
              isSelected: widget.currentVersion == 2,
              onTap: () => _selectVersion(context, 2),
            ),
            const SizedBox(height: 16),
            _VersionOption(
              version: 3,
              title: "profile.design.versions.minimalist.name".tr(),
              description: "profile.design.versions.minimalist.description"
                  .tr(),
              isSelected: widget.currentVersion == 3,
              onTap: () => _selectVersion(context, 3),
            ),
            const SizedBox(height: 24),

            // Botón cerrar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "profile.design.cancelButton".tr(),
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectVersion(BuildContext context, int version) async {
    if (version == widget.currentVersion) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // Actualizar la versión en el AuthCubit
      await context.read<AuthCubit>().updateProfileVersion(version);

      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diseño actualizado a Versión $version'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar diseño: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _VersionOption extends StatelessWidget {
  final int version;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionOption({
    required this.version,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icono/Número
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  version.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark si está seleccionado
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.purple, size: 28),
          ],
        ),
      ),
    );
  }
}
