import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:http/http.dart' as http;

class WebAddCustomLinkModal extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final bool isRegister;

  const WebAddCustomLinkModal({
    super.key,
    required this.onComplete,
    required this.onBack,
    this.isRegister = false,
  });

  @override
  State<WebAddCustomLinkModal> createState() => _WebAddCustomLinkModalState();
}

class _WebAddCustomLinkModalState extends State<WebAddCustomLinkModal> {
  final TextEditingController _linkCtrl = TextEditingController(
    text: 'https://',
  );
  bool _applyIconFromLink = false;

  // Image handling
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  String? _pickedImageUrl;

  bool _isSaving = false;
  String? _error;

  int _faviconRequestId = 0;

  @override
  void initState() {
    super.initState();
    _linkCtrl.addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _faviconRequestId++;
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        // Size validation (5MB)
        if (bytes.lengthInBytes > 5 * 1024 * 1024) {
          setState(
            () =>
                _error = 'profile.customization.customLink.imageTooLarge'.tr(),
          );
          return;
        }

        setState(() {
          _pickedFile = image;
          _pickedBytes = bytes;
          _pickedImageUrl = null;
          _error = null;
          _applyIconFromLink = false; // Disable favicon switch
        });
      }
    } catch (e) {
      setState(
        () =>
            _error = '${'profile.customization.plataform.imageError'.tr()} $e',
      );
    }
  }

  String _domainFromUrl(String url) {
    final normalized = url.contains('://') ? url : 'https://$url';
    final host = Uri.parse(normalized).host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _faviconFromDomain(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  Future<String?> _resolveFavicon(String domain) async {
    return _faviconFromDomain(domain);
  }

  Future<void> _setFaviconFromDomain(String domain) async {
    final requestId = ++_faviconRequestId;
    final url = await _resolveFavicon(domain);
    if (!mounted) return;
    if (requestId != _faviconRequestId) return;
    setState(() {
      _pickedImageUrl = url;
      _pickedBytes = null;
      _pickedFile = null;
    });
  }

  String? _validateLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'profile.customization.customLink.validation.required'.tr();
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      return 'profile.customization.customLink.validation.invalidFormat'.tr();
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'profile.customization.customLink.validation.invalidScheme'.tr();
    }
    return null;
  }

  Future<String?> _uploadWebImage(XFile file, String userId) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBase}/users/upload-file'),
      );

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      request.fields['folder'] = MediaType.document.name;
      request.fields['user_id'] = userId;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        throw Exception('Error uploading file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final linkError = _validateLink(_linkCtrl.text);
    if (linkError != null) {
      setState(() {
        _error = linkError;
        _isSaving = false;
      });
      return;
    }

    // Auth check only for Edit Mode
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (!widget.isRegister && userId == null) {
      setState(() {
        _error = 'edit.validations.errorUserLogin'.tr();
        _isSaving = false;
      });
      return;
    }

    if (!widget.isRegister) {
      showProfileLoader(context, message: 'common.loader_sequence.saving'.tr());
    }

    try {
      final link = _linkCtrl.text.trim();
      final domain = _domainFromUrl(link);
      String? iconUrl;

      // Handle Icon
      if (_applyIconFromLink) {
        iconUrl = await _resolveFavicon(domain);
      } else if (_pickedFile != null && !widget.isRegister) {
        // Upload only if user is logged in (Edit Mode)
        if (userId != null) {
          iconUrl = await _uploadWebImage(_pickedFile!, userId);
          if (iconUrl == null) throw Exception('Failed to upload image');
        }
      }

      final data = <String, dynamic>{
        'type': 'custom',
        'domain': domain,
        'url': link,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'applyIconFromLink': _applyIconFromLink,
        'createdAt': Timestamp.now(),
      };

      if (widget.isRegister) {
        // --- Register Mode ---
        // ignore: use_build_context_synchronously
        final registerCubit = context.read<RegisterCubit>();
        final current = List<Map<String, dynamic>>.from(
          registerCubit.state.socialEcosystem ?? [],
        );
        current.add(data);
        registerCubit.setSocialEcosystem(current);

        if (mounted) {
          widget.onComplete();
        }
      } else {
        // --- Edit Mode ---
        // ignore: use_build_context_synchronously
        final editCubit = context.read<EditCubit>();
        final current = List<Map<String, dynamic>>.from(
          editCubit.state.socialEcosystem ?? [],
        );

        current.add(data);

        editCubit.updateSocialEcosystem(current);
        if (userId != null) {
          await editCubit.saveAllPendingChanges(userId);
        }

        if (mounted) Navigator.pop(context); // Close loader

        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: 'profile.customization.customLink.saved'.tr(),
            type: SnackbarType.success,
          );
          widget.onComplete();
        }
      }
    } catch (e) {
      debugPrint('Error saving custom link: $e');
      if (!widget.isRegister && mounted) Navigator.pop(context); // Close loader
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      alignment: Alignment.center,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B3D), Color(0xFF1A0F2E)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        'profile.customization.customLink.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Image Picker Area
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            image: (_pickedImageUrl != null)
                                ? DecorationImage(
                                    image: NetworkImage(_pickedImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (_pickedImageUrl == null && _pickedBytes == null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white54,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : (_pickedBytes != null)
                              ? ClipOval(
                                  child: Image.memory(
                                    _pickedBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // URL Input
                      TextField(
                        controller: _linkCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'profile.customization.customLink.linkHint'
                              .tr(),
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.link,
                            color: Colors.white54,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fetch Icon Switch
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'profile.customization.customLink.applyIconFromLink'
                                    .tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Switch(
                              value: _applyIconFromLink,
                              activeThumbColor: AppColors.primaryPink,
                              activeTrackColor: AppColors.primaryPink
                                  .withValues(alpha: 0.3),
                              onChanged: (val) {
                                setState(() => _applyIconFromLink = val);
                                if (val) _onLinkChanged();
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'buttons.save'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
