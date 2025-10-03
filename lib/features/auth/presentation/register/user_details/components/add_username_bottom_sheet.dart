import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'dart:io';

class AddUsernameBottomSheet extends StatefulWidget {
  final Map<String, String> platformData;
  final Function(Map<String, String>) onPlatformAdded;

  const AddUsernameBottomSheet({
    super.key,
    required this.platformData,
    required this.onPlatformAdded,
  });

  @override
  State<AddUsernameBottomSheet> createState() => _AddUsernameBottomSheetState();
}

class _AddUsernameBottomSheetState extends State<AddUsernameBottomSheet> {
  final TextEditingController _usernameController = TextEditingController();

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
          bottom: MediaQuery.of(context).viewInsets.bottom
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
                  "Add ${widget.platformData['name']}",
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

            // Logo de la plataforma (centrado y grande)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    widget.platformData['logo'] != null &&
                        widget.platformData['logo']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.platformData['logo']!),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : const Icon(Icons.language, color: Colors.white, size: 40),
              ),
            ),

            const SizedBox(height: 20),

            // Campo de username
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

            // URL de la plataforma (solo lectura)
            if (widget.platformData['link'] != null &&
                widget.platformData['link']!.isNotEmpty)
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
                        widget.platformData['link']!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GradientButton(
                onPressed: () {
                  // Validar que el username esté completo
                  if (_usernameController.text.trim().isNotEmpty) {
                    // Agregar el username a los datos de la plataforma
                    final completePlatformData = Map<String, String>.from(
                      widget.platformData,
                    );
                    completePlatformData['username'] = _usernameController.text
                        .trim();

                    // Llamar al callback para agregar la plataforma completa
                    widget.onPlatformAdded(completePlatformData);

                    // Cerrar el bottom sheet
                    Navigator.pop(context);
                  } else {
                    // Mostrar mensaje de error si no hay username
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a username'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                width: double.infinity,
                radius: 25,
                gradient: AppColors.primaryGradient,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
