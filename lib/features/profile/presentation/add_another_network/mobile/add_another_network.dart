import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
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
  DateTime? _loaderStart;

  @override
  void initState() {
    super.initState();
    _linkCtrl.addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _linkCtrl.removeListener(_onLinkChanged);
    _linkCtrl.dispose();
    super.dispose();
  }

  void _onLinkChanged() {
    if (_applyIconFromLink) {
      final text = _linkCtrl.text.trim();
      if (text.isNotEmpty) {
        final domain = _domainFromUrl(text);
        _setFaviconFromDomain(domain);
      } else {
        if (_pickedImageUrl != null) {
          setState(() {
            _pickedImageUrl = null;
          });
        }
      }
    }
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

  Future<void> _showLoader({String message = 'Cargando...'}) async {
    _loaderStart = DateTime.now();
    showProfileLoader(context, message: message, barrierDismissible: false);
  }

  Future<void> _ensureMinLoaderThenPop([
    Duration min = const Duration(seconds: 2),
  ]) async {
    final start = _loaderStart;
    if (start != null) {
      final elapsed = DateTime.now().difference(start);
      final remaining = min - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
      _loaderStart = null;
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
    final normalized = url.contains('://') ? url : 'https://$url';
    final host = Uri.parse(normalized).host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _faviconFromDomain(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  // String _duckFaviconFromDomain(String domain) {
  //   return 'https://icons.duckduckgo.com/ip3/$domain.ico';
  // }

  Future<String?> _resolveFavicon(String domain) async {
    bool _isSupported(String? ct) {
      if (ct == null) return false;
      final v = ct.toLowerCase();
      return v.contains('image/png') ||
          v.contains('image/jpeg') ||
          v.contains('image/webp') ||
          v.contains('image/gif') ||
          v.contains('image/svg+xml');
    }

    final candidates = <String>[
      _faviconFromDomain(domain),
      'https://s2.googleusercontent.com/s2/favicons?domain=$domain&sz=128',
      'https://$domain/favicon.svg',
      'https://$domain/favicon.png',
      'https://$domain/apple-touch-icon.png',
      'https://$domain/icon.png',
    ];
    for (final url in candidates) {
      try {
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse(url));
        final res = await req.close();
        final ct = res.headers.value('content-type');
        if (res.statusCode >= 200 && res.statusCode < 400 && _isSupported(ct)) {
          return url;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _setFaviconFromDomain(String domain) async {
    final url = await _resolveFavicon(domain);
    setState(() {
      _pickedImageUrl = url;
      _pickedImage = null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });
    await _showLoader(message: 'Guardando...');

    final linkError = _validateLink(_linkCtrl.text);
    if (linkError != null) {
      _error = linkError;
      await _ensureMinLoaderThenPop();
      setState(() => _isSaving = false);
      await AlertGeneral.show(context, 4, message: linkError);
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      await _ensureMinLoaderThenPop();
      setState(() => _isSaving = false);
      await AlertGeneral.show(context, 4, message: 'Error: User not logged in');
      return;
    }

    try {
      String? iconUrl;
      final link = _linkCtrl.text.trim();
      final domain = _domainFromUrl(link);

      if (_applyIconFromLink) {
        iconUrl = await _resolveFavicon(domain);
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
        'domain': domain,
        'url': link,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'applyIconFromLink': _applyIconFromLink,
        'createdAt':
            Timestamp.now(), // Corregido: serverTimestamp no soportado en arrays
      };

      current.add(data);

      await editCubit.saveUserProfileField(
        userId: userId,
        updatedFields: {'socialEcosystem': current},
      );

      if (!mounted) return;
      await _ensureMinLoaderThenPop();
      setState(() => _isSaving = false);

      await AlertGeneral.show(
        context,
        1,
        message: 'Red personalizada guardada',
      );
      if (mounted) {
        Navigator.pop(context, 'done');
      }
    } catch (e) {
      await _ensureMinLoaderThenPop();
      setState(() => _isSaving = false);
      await AlertGeneral.show(context, 4, message: 'Error guardando: $e');
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
        .where((entry) => entry['domain'] != domain)
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
                          activeColor: Colors.white,
                          onChanged: (v) {
                            setState(() {
                              _applyIconFromLink = v;
                            });
                            if (v && _linkCtrl.text.trim().isNotEmpty) {
                              final domain = _domainFromUrl(
                                _linkCtrl.text.trim(),
                              );
                              _setFaviconFromDomain(domain);
                            } else {
                              setState(() {
                                _pickedImageUrl = null;
                              });
                            }
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
