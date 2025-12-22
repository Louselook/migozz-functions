import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/utils/camera_permission_handler.dart';
import 'dart:io';
import 'add_username_bottom_sheet.dart';

class AddPlatformBottomSheet extends StatefulWidget {
  final Function(Map<String, String>) onPlatformAdded;

  const AddPlatformBottomSheet({super.key, required this.onPlatformAdded});

  @override
  State<AddPlatformBottomSheet> createState() => _AddPlatformBottomSheetState();
}

class _AddPlatformBottomSheetState extends State<AddPlatformBottomSheet> {
  final TextEditingController _platformNameController = TextEditingController();
  final TextEditingController _profileLinkController = TextEditingController();
  File? _selectedImage;

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'profile.customization.plataform.image'.tr(),
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text(
                  'profile.customization.plataform.camera'.tr(),
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(
                  'profile.customization.plataform.gallery'.tr(),
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final imagePath = await CameraPermissionHandler.openCamera(
        imageQuality: 40,
        context: context,
      );

      if (imagePath != null) {
        setState(() {
          _selectedImage = File(imagePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'profile.customization.plataform.camera'.tr()} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final imagePath = await CameraPermissionHandler.openGallery(
        imageQuality: 40,
        context: context,
      );

      if (imagePath != null) {
        setState(() {
          _selectedImage = File(imagePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'profile.customization.plataform.gallery'.tr()} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUsernameBottomSheet(
    BuildContext context,
    Map<String, String> platformData,
    Function(Map<String, String>) onPlatformAdded,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddUsernameBottomSheet(
        platformData: platformData,
        onPlatformAdded: onPlatformAdded,
      ),
    );
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
                  'profile.customization.plataform.title'.tr(),
                  style: TextStyle(
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

            // Add Platform Name
            Text(
              'profile.customization.plataform.addName'.tr(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _platformNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'profile.customization.plataform.gallery'.tr(),
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Add Platform Logo
            Text(
              'profile.customization.plataform.addUsername'.tr(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D3D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 100,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'profile.customization.plataform.addTapLogo'.tr(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Add Profile Link
            Text(
              'profile.customization.plataform.addLink'.tr(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _profileLinkController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "+ Enter custom Link",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GradientButton(
                onPressed: () {
                  // Validar que al menos el nombre esté completo
                  if (_platformNameController.text.trim().isNotEmpty) {
                    // Crear el mapa con los datos de la plataforma (sin username aún)
                    final platformData = {
                      'name': _platformNameController.text.trim(),
                      'link': _profileLinkController.text.trim(),
                      'logo': _selectedImage?.path ?? '',
                    };

                    // Cerrar el primer bottom sheet
                    Navigator.pop(context);

                    // Abrir el segundo bottom sheet para agregar username
                    _showUsernameBottomSheet(
                      context,
                      platformData,
                      widget.onPlatformAdded,
                    );
                  } else {
                    // Mostrar mensaje de error si no hay nombre
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a platform name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                width: double.infinity,
                radius: 25,
                gradient: AppColors.primaryGradient,
                child: Text(
                  'buttons.save'.tr(),
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
    _platformNameController.dispose();
    _profileLinkController.dispose();
    super.dispose();
  }
}
