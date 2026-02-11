import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';

import '../../../../../../../core/assets_constants.dart';

enum ContactType { website, phone, email }

Stack placeHolderWidget(Size size) {
  return Stack(
    alignment: Alignment.center,
    children: [
      SvgPicture.asset(
        AssetsConstants.placeholderIcon,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height * 0.3,
      ),
    ],
  );
}

class AddContactInfoBottomSheet extends StatefulWidget {
  final ContactType type;
  final Function(String value) onSave;
  final VoidCallback? onDelete;
  final String? currentValue;

  const AddContactInfoBottomSheet({
    super.key,
    required this.type,
    required this.onSave,
    this.onDelete,
    this.currentValue,
  });

  @override
  State<AddContactInfoBottomSheet> createState() =>
      _AddContactInfoBottomSheetState();
}

class _AddContactInfoBottomSheetState extends State<AddContactInfoBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // For website, pre-fill https:// if no current value
    String initialValue;
    if (widget.type == ContactType.website) {
      if (widget.currentValue != null && widget.currentValue!.isNotEmpty) {
        initialValue = widget.currentValue!;
      } else {
        initialValue = 'https://';
      }
    } else {
      initialValue = widget.currentValue ?? '';
    }
    _controller = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTypeLabel(BuildContext context) {
    switch (widget.type) {
      case ContactType.website:
        return 'profile.customization.contact.sheetType.website'.tr();
      case ContactType.phone:
        return 'profile.customization.contact.sheetType.phone'.tr();
      case ContactType.email:
        return 'profile.customization.contact.sheetType.email'.tr();
    }
  }

  String _getTitle(BuildContext context) {
    final isEditing =
        widget.currentValue != null && widget.currentValue!.isNotEmpty;
    final actionKey = isEditing
        ? 'profile.customization.contact.sheetTitle.edit'
        : 'profile.customization.contact.sheetTitle.add';
    return actionKey.tr(namedArgs: {'type': _getTypeLabel(context)});
  }

  String _getHint(BuildContext context) {
    switch (widget.type) {
      case ContactType.website:
        return 'profile.customization.contact.hints.website'.tr();
      case ContactType.phone:
        return 'profile.customization.contact.hints.phone'.tr();
      case ContactType.email:
        return 'profile.customization.contact.hints.email'.tr();
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case ContactType.website:
        return TextInputType.url;
      case ContactType.phone:
        return TextInputType.phone;
      case ContactType.email:
        return TextInputType.emailAddress;
    }
  }

  String? _validate(String value) {
    if (value.isEmpty) {
      return 'profile.customization.contact.validation.required'.tr();
    }

    switch (widget.type) {
      case ContactType.website:
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return 'profile.customization.contact.validation.websiteFormat'.tr();
        }
        break;
      case ContactType.email:
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'profile.customization.contact.validation.emailFormat'.tr();
        }
        break;
      case ContactType.phone:
        if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
          return 'profile.customization.contact.validation.phoneFormat'.tr();
        }
        break;
    }
    return null;
  }

  void _handleSave() {
    final value = _controller.text.trim();
    final error = _validate(value);

    if (error != null) {
      AlertGeneral.show(context, 4, message: error);
      return;
    }

    widget.onSave(value);
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
                    _getTitle(context),
                    style: const TextStyle(
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

              // Input field
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                keyboardType: _getKeyboardType(),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _getHint(context),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
                    'buttons.save'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Delete button (only show when editing)
              if (widget.onDelete != null &&
                  widget.currentValue != null &&
                  widget.currentValue!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      widget.onDelete?.call();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'buttons.delete'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
