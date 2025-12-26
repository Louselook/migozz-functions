import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class AddLinkBottomSheet extends StatefulWidget {
  final Function(String url, String label) onLinkAdded;

  const AddLinkBottomSheet({
    super.key,
    required this.onLinkAdded,
  });

  @override
  State<AddLinkBottomSheet> createState() => _AddLinkBottomSheetState();
}

class _AddLinkBottomSheetState extends State<AddLinkBottomSheet> {
  final TextEditingController _urlController = TextEditingController(text: 'https://');
  final TextEditingController _labelController = TextEditingController();
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Check if it has a valid scheme and host
      return (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          uri.host.contains('.');
    } catch (e) {
      return false;
    }
  }

  void _handleSave() {
    String url = _urlController.text.trim();
    final label = _labelController.text.trim();

    // Clear previous error
    setState(() {
      _urlError = null;
    });

    // Check if URL is empty or just the prefix
    if (url.isEmpty || url == 'https://' || url == 'http://') {
      setState(() {
        _urlError = 'profile.customization.links.validationEmptyUrl'.tr();
      });
      return;
    }

    // Auto-add https:// prefix if user removed it
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Validate URL format
    if (!_isValidUrl(url)) {
      setState(() {
        _urlError = 'profile.customization.links.validationInvalidUrl'.tr();
      });
      return;
    }

    widget.onLinkAdded(
      url,
      label.isEmpty ? 'profile.customization.links.defaultLabel'.tr() : label,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profile.customization.links.sheetTitle'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Label input
              TextField(
                controller: _labelController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'profile.customization.links.labelHint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // URL input
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  // Clear error when user starts typing
                  if (_urlError != null) {
                    setState(() {
                      _urlError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'profile.customization.links.urlHint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _urlError != null
                        ? const BorderSide(color: Colors.red, width: 1)
                        : BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _urlError != null
                        ? const BorderSide(color: Colors.red, width: 1)
                        : BorderSide.none,
                  ),
                  errorText: _urlError,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: _handleSave,
                  gradient: AppColors.primaryGradient,
                  radius: 10,
                  height: 48,
                  child: Text(
                    'profile.customization.links.save'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

