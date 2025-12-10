import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'components/image_upload_area.dart';

class AddAnotherNetworkScreen extends StatefulWidget {
  const AddAnotherNetworkScreen({super.key});

  @override
  State<AddAnotherNetworkScreen> createState() =>
      _AddAnotherNetworkScreenState();
}

class _AddAnotherNetworkScreenState extends State<AddAnotherNetworkScreen> {
  final TextEditingController _linkCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _pickedImage;
  String? _pickedImageUrl;
  bool _applyIconFromLink = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 85);
      if (xfile == null) return;
      final file = File(xfile.path);

      final sizeBytes = await file.length();
      final lower = file.path.toLowerCase();
      final allowed =
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp');

      if (!allowed) {
        setState(() => _error = 'Tipo de imagen no permitido');
        return;
      }
      if (sizeBytes > 5 * 1024 * 1024) {
        setState(() => _error = 'La imagen supera 5MB');
        return;
      }

      setState(() {
        _pickedImage = file;
        _pickedImageUrl = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Error seleccionando imagen: $e');
    }
  }

  String? _validateLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'El link es obligatorio';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      return 'Formato de link inválido';
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'El link debe iniciar con http/https';
    }
    return null;
  }

  String _domainFromUrl(String url) {
    final host = Uri.parse(url).host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _faviconFromDomain(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final linkError = _validateLink(_linkCtrl.text);
    if (linkError != null) {
      setState(() => _error = linkError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(linkError), backgroundColor: Colors.red),
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      String? iconUrl;
      final link = _linkCtrl.text.trim();
      final domain = _domainFromUrl(link);

      if (_applyIconFromLink) {
        iconUrl = _faviconFromDomain(domain);
        setState(() => _pickedImageUrl = iconUrl);
      } else if (_pickedImage != null) {
        final service = UserMediaService();
        final urls = await service.uploadFiles(
          uid: userId,
          files: {MediaType.document: _pickedImage!},
        );
        iconUrl = urls[MediaType.document];
      }

      final current = List<Map<String, dynamic>>.from(
        authCubit.state.userProfile?.socialEcosystem ?? [],
      );

      final data = <String, dynamic>{
        'type': 'custom',
        'url': link,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      current.add({domain: data});

      await editCubit.saveUserProfileField(
        userId: userId,
        updatedFields: {'socialEcosystem': current},
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Red personalizada guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, 'done');
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error guardando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteIfExists() async {
    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) return;

    final linkError = _validateLink(_linkCtrl.text);
    if (linkError != null) {
      setState(() {
        _pickedImage = null;
        _pickedImageUrl = null;
        _linkCtrl.clear();
        _applyIconFromLink = false;
        _error = null;
      });
      return;
    }

    final link = _linkCtrl.text.trim();
    final domain = _domainFromUrl(link);
    final current = List<Map<String, dynamic>>.from(
      authCubit.state.userProfile?.socialEcosystem ?? [],
    );

    final updated = current
        .where((entry) => !entry.containsKey(domain))
        .toList();

    await editCubit.saveUserProfileField(
      userId: userId,
      updatedFields: {'socialEcosystem': updated},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link eliminado'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _pickedImage = null;
        _pickedImageUrl = null;
        _linkCtrl.clear();
        _applyIconFromLink = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0220),
      body: Stack(
        children: [
          Positioned(
            left: -80,
            top: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF7B2CF6), Color(0x001A0220)],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Custom Link Icon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ImageUploadArea(
                      imageFile: _pickedImage,
                      imageUrl: _pickedImageUrl,
                      size: isSmall ? 140 : 180,
                      onTap: _openPickerSheet,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _linkCtrl,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add custom Link',
                        hintStyle: const TextStyle(color: Color(0xFFE0E0E0)),
                        filled: true,
                        fillColor: const Color(0xFF7C7480),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Apply Custom Icon from Link',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Switch(
                          value: _applyIconFromLink,
                          inactiveTrackColor: const Color(0xFF5E5564),
                          activeTrackColor: const Color(0xFF5E5564),
                          activeThumbColor: Colors.white,
                          onChanged: (v) {
                            setState(() {
                              _applyIconFromLink = v;
                              if (v && _linkCtrl.text.trim().isNotEmpty) {
                                final domain = _domainFromUrl(
                                  _linkCtrl.text.trim(),
                                );
                                _pickedImageUrl = _faviconFromDomain(domain);
                                _pickedImage = null;
                              } else {
                                _pickedImageUrl = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: _isSaving ? null : _save,
                        height: 48,
                        radius: 24,
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _deleteIfExists,
                      child: const Text(
                        'Delete Link',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
