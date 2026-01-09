import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/utils/camera_permission_handler.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'components/image_upload_area.dart';

class AddAnotherNetworkScreen extends StatefulWidget {
  final bool allowUnauthenticated;

  const AddAnotherNetworkScreen({
    super.key,
    this.allowUnauthenticated = false,
  });

  @override
  State<AddAnotherNetworkScreen> createState() =>
      _AddAnotherNetworkScreenState();
}

class _AddAnotherNetworkScreenState extends State<AddAnotherNetworkScreen> {
  final TextEditingController _linkCtrl = TextEditingController(text: 'https://');

  File? _pickedImage;
  String? _pickedImageUrl;
  bool _applyIconFromLink = false;
  bool _isSaving = false;
  String? _error;
  DateTime? _loaderStart;

  int _faviconRequestId = 0;

  @override
  void initState() {
    super.initState();
    _linkCtrl.addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _faviconRequestId++; // invalidar callbacks async pendientes
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
          if (!mounted) return;
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
              title: Text(
                'profile.customization.plataform.gallery'.tr(),
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: Text(
                'profile.customization.plataform.camera'.tr(),
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final imagePath = await CameraPermissionHandler.openGallery(
        imageQuality: 85,
        context: context,
      );

      if (imagePath == null) return;

      await _validateAndSetImage(imagePath);
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _error = '${'profile.customization.plataform.imageError'.tr()} $e',
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final imagePath = await CameraPermissionHandler.openCamera(
        imageQuality: 85,
        context: context,
      );

      if (imagePath == null) return;

      await _validateAndSetImage(imagePath);
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _error = '${'profile.customization.plataform.imageError'.tr()} $e',
      );
    }
  }

  Future<void> _validateAndSetImage(String imagePath) async {
    final file = File(imagePath);

    final sizeBytes = await file.length();
    final lower = file.path.toLowerCase();
    final allowed =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (!allowed) {
      if (!mounted) return;
      setState(
        () =>
            _error = 'profile.customization.customLink.imageTypeNotAllowed'
                .tr(),
      );
      return;
    }
    if (sizeBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(
        () => _error = 'profile.customization.customLink.imageTooLarge'.tr(),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _pickedImage = file;
      _pickedImageUrl = null;
      _error = null;
    });
  }

  Future<void> _showLoader({
    String? message,
  }) async {
    _loaderStart = DateTime.now();
    showProfileLoader(
      context,
      message: message ?? 'common.loading'.tr(),
      barrierDismissible: false,
    );
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
    if (trimmed.isEmpty) return 'profile.customization.customLink.validation.required'.tr();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      return 'profile.customization.customLink.validation.invalidFormat'.tr();
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'profile.customization.customLink.validation.invalidScheme'.tr();
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
    bool isSupported(String? ct) {
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
        if (res.statusCode >= 200 && res.statusCode < 400 && isSupported(ct)) {
          return url;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _setFaviconFromDomain(String domain) async {
    final requestId = ++_faviconRequestId;
    final url = await _resolveFavicon(domain);
    if (!mounted) return;
    if (requestId != _faviconRequestId) return;
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
    await _showLoader(message: 'common.saving'.tr());

    final linkError = _validateLink(_linkCtrl.text);
    if (linkError != null) {
      _error = linkError;
      await _ensureMinLoaderThenPop();
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (!context.mounted) return;
      await AlertGeneral.show(context, 4, message: linkError);
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      if (widget.allowUnauthenticated) {
        final link = _linkCtrl.text.trim();
        final domain = _domainFromUrl(link);

        String? iconUrl;
        if (_applyIconFromLink) {
          iconUrl = await _resolveFavicon(domain);
        }

        final data = <String, dynamic>{
          'type': 'custom',
          'domain': domain,
          'url': link,
          if (iconUrl != null) 'iconUrl': iconUrl,
          'applyIconFromLink': _applyIconFromLink,
        };

        await _ensureMinLoaderThenPop();
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (!context.mounted) return;
        Navigator.pop(context, data);
        return;
      }

      await _ensureMinLoaderThenPop();
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (!context.mounted) return;
      await AlertGeneral.show(
        context,
        4,
        message: 'edit.validations.errorUserLogin'.tr(),
      );
      return;
    }

    try {
      String? iconUrl;
      final link = _linkCtrl.text.trim();
      final domain = _domainFromUrl(link);

      if (_applyIconFromLink) {
        iconUrl = await _resolveFavicon(domain);
        if (!mounted) return;
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
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (!context.mounted) return;
      await AlertGeneral.show(
        context,
        1,
        message: 'profile.customization.customLink.saved'.tr(),
      );
      if (context.mounted) {
        Navigator.pop(context, 'done');
      }
    } catch (e) {
      await _ensureMinLoaderThenPop();
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (!context.mounted) return;
      await AlertGeneral.show(
        context,
        4,
        message: '${'profile.customization.customLink.errorSave'.tr()}$e',
      );
    }
  }

  Future<void> _deleteIfExists() async {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) {
      setState(() {
        _pickedImage = null;
        _pickedImageUrl = null;
        _linkCtrl.clear();
        _applyIconFromLink = false;
        _error = null;
      });
      return;
    }

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
        SnackBar(
          content: Text('profile.customization.customLink.deleted'.tr()),
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
                    Text(
                      'profile.customization.customLink.title'.tr(),
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
                        hintText:
                            'profile.customization.customLink.linkHint'.tr(),
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
                        Expanded(
                          child: Text(
                            'profile.customization.customLink.applyIconFromLink'
                                .tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Switch(
                          value: _applyIconFromLink,
                          inactiveTrackColor: const Color(0xFF5E5564),
                          activeTrackColor: const Color(0xFF5E5564),
                          // activeThumbColor: Colors.white,
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
                            : Text(
                                'buttons.save'.tr(),
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
                      child: Text(
                        'profile.customization.customLink.deleteLink'.tr(),
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


