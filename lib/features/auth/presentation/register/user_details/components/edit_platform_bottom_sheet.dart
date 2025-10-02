import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'dart:io';

class EditPlatformBottomSheet extends StatefulWidget {
  final Map<String, String> platform;
  final Function(Map<String, String>) onPlatformUpdated;
  final VoidCallback onPlatformDeleted;

  const EditPlatformBottomSheet({
    super.key,
    required this.platform,
    required this.onPlatformUpdated,
    required this.onPlatformDeleted,
  });

  @override
  State<EditPlatformBottomSheet> createState() =>
      _EditPlatformBottomSheetState();
}

class _EditPlatformBottomSheetState extends State<EditPlatformBottomSheet> {
  late TextEditingController _usernameController;
  String _dynamicUrl = '';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.platform['username'] ?? '',
    );
    _updateUrl(_usernameController.text);

    // Listener para actualizar la URL dinámicamente
    _usernameController.addListener(() {
      _updateUrl(_usernameController.text);
    });
  }

  void _updateUrl(String username) {
    setState(() {
      if (username.isNotEmpty &&
          widget.platform['link'] != null &&
          widget.platform['link']!.isNotEmpty) {
        // Ejemplo: https://www.instagram.com/username
        _dynamicUrl = '${widget.platform['link']}/$username';
      } else {
        _dynamicUrl = widget.platform['link'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con botón cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Edit ${widget.platform['name']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Logo de la plataforma (centrado y grande) - SOLO VISUAL
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    widget.platform['logo'] != null &&
                        widget.platform['logo']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.platform['logo']!),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : const Icon(Icons.language, color: Colors.white, size: 40),
              ),
            ),

            const SizedBox(height: 20),

            // Campo de username EDITABLE
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Enter username",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // URL DINÁMICA (solo lectura, cambia según el username)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _dynamicUrl,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Botones de acción
            Row(
              children: [
                // Botón eliminar
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onPlatformDeleted();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // Botón guardar cambios
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: GradientButton(
                      onPressed: () {
                        // Actualizar los datos de la plataforma
                        final updatedPlatform = Map<String, String>.from(
                          widget.platform,
                        );
                        updatedPlatform['username'] = _usernameController.text
                            .trim();

                        widget.onPlatformUpdated(updatedPlatform);
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      radius: 25,
                      gradient: AppColors.primaryGradient,
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
