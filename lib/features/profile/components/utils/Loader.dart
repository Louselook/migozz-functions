import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum LoaderType {
  login,
  profileUpdate,
  qrScan,
  socialAuth,
  logout,
  generic, // Fallback
}

Future<void> showProfileLoader(
  BuildContext context, {
  String? message,
  String? platform,
  LoaderType type = LoaderType.generic,
  VoidCallback? onCancel,
  bool barrierDismissible = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'common.loader'.tr(),
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, a1, a2) => Center(
      child: LoaderDialog(
        message: message,
        platform: platform,
        type: type,
        onCancel: onCancel,
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
        child: child,
      ),
    ),
  );
}

class LoaderDialog extends StatefulWidget {
  final String? message;
  final String? platform;
  final LoaderType type;
  final VoidCallback? onCancel;

  const LoaderDialog({
    super.key,
    this.message,
    this.platform,
    this.type = LoaderType.generic,
    this.onCancel,
  });

  @override
  State<LoaderDialog> createState() => _LoaderDialogState();
}

class _LoaderDialogState extends State<LoaderDialog> {
  late String _displayMessage;

  @override
  void initState() {
    super.initState();

    if (widget.message != null) {
      _displayMessage = widget.message!;
    } else {
      // Usar mensaje según el tipo de loader
      _displayMessage = _getMessageForType(widget.type);
    }
  }

  String _getMessageForType(LoaderType type) {
    switch (type) {
      case LoaderType.login:
        return 'common.loader_sequences.login.step1'.tr();
      case LoaderType.profileUpdate:
        return 'common.loader_sequences.profile_update.step1'.tr();
      case LoaderType.qrScan:
        return 'common.loader_sequences.qr_scan.step1'.tr();
      case LoaderType.socialAuth:
        return 'common.loader_sequences.social_auth.step2'.tr(
          namedArgs: {'platform': widget.platform ?? 'Migozz'},
        );
      case LoaderType.logout:
        return 'common.loader_sequences.logout.step1'.tr();
      default:
        return 'common.loading'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF7B2CF5), Color(0xFFFF3D6E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Image.asset(
              'assets/images/Loader.gif',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _displayMessage,
                key: ValueKey(_displayMessage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
