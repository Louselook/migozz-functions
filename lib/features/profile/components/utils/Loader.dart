import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum LoaderType {
  login,
  profileUpdate,
  qrScan,
  socialAuth,
  logout,
  registration,
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
  Timer? _messageTimer;
  List<String> _sequenceMessages = const [];
  int _sequenceIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.message != null) {
      _displayMessage = widget.message!;
      _sequenceMessages = [widget.message!];
    } else {
      _sequenceMessages = _getSequenceMessages(widget.type);
    }

    _sequenceIndex = 0;
    _displayMessage = _sequenceMessages.isNotEmpty
        ? _sequenceMessages[0]
        : 'common.loading'.tr();

    // Avanza cada 2 segundos sin loop.
    // Cada mensaje se muestra mínimo 2 segundos.
    // Al llegar al último, se queda hasta que se cierre el dialog.
    if (_sequenceMessages.length > 1) {
      _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        _sequenceIndex++;

        // Último mensaje alcanzado → detener, sin volver al inicio.
        if (_sequenceIndex >= _sequenceMessages.length) {
          timer.cancel();
          return;
        }

        setState(() {
          _displayMessage = _sequenceMessages[_sequenceIndex];
        });
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  List<String> _getSequenceMessages(LoaderType type) {
    switch (type) {
      case LoaderType.login:
        return [
          'common.loader_sequences.login.step1'.tr(),
          'common.loader_sequences.login.step2'.tr(),
          'common.loader_sequences.login.step3'.tr(),
          'common.loader_sequence.delay'.tr(),
        ];
      case LoaderType.registration:
        return [
          'common.loader_sequences.registration.step1'.tr(),
          'common.loader_sequences.registration.step2'.tr(),
          'common.loader_sequences.registration.step3'.tr(),
          'common.loader_sequences.registration.step4'.tr(),
          'common.loader_sequences.registration.step5'.tr(),
          'common.loader_sequences.registration.step6'.tr(),
        ];
      case LoaderType.profileUpdate:
        return [
          'common.loader_sequences.profile_update.step1'.tr(),
          'common.loader_sequences.profile_update.step2'.tr(),
          'common.loader_sequences.profile_update.step3'.tr(),
          'common.loader_sequence.delay'.tr(),
        ];
      case LoaderType.qrScan:
        return [
          'common.loader_sequences.qr_scan.step1'.tr(),
          'common.loader_sequences.qr_scan.step2'.tr(),
          'common.loader_sequences.qr_scan.step3'.tr(),
          'common.loader_sequence.delay'.tr(),
        ];
      case LoaderType.logout:
        return [
          'common.loader_sequences.logout.step1'.tr(),
          'common.loader_sequences.logout.step2'.tr(),
          'common.loader_sequences.logout.step3'.tr(),
          'common.loader_sequence.delay'.tr(),
        ];
      case LoaderType.socialAuth:
        return [
          'common.loader_sequences.social_auth.step1'.tr(
            namedArgs: {'platform': widget.platform ?? 'Social'},
          ),
          'common.loader_sequences.social_auth.step2'.tr(
            namedArgs: {'platform': widget.platform ?? 'Social'},
          ),
          'common.loader_sequences.social_auth.step3'.tr(
            namedArgs: {'platform': widget.platform ?? 'Social'},
          ),
          'common.loader_sequence.delay'.tr(),
        ];
      default:
        return ['common.loading'.tr(), 'common.loader_sequence.delay'.tr()];
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
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _displayMessage,
                  key: ValueKey(_displayMessage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.4,
                  ),
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
