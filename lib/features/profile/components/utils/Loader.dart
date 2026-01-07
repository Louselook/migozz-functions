import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showProfileLoader(
  BuildContext context, {
  String? message,
  String? platform,
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
  final VoidCallback? onCancel;

  const LoaderDialog({
    super.key,
    this.message,
    this.platform,
    this.onCancel,
  });

  @override
  State<LoaderDialog> createState() => _LoaderDialogState();
}

class _LoaderDialogState extends State<LoaderDialog> {
  late String _displayMessage;
  Timer? _sequenceTimer;
  Timer? _delayTimer;
  int _currentStep = 0;
  bool _showingDelay = false;

  final List<String> _steps = [
    'common.loader_sequence.connecting',
    'common.loader_sequence.validating',
    'common.loader_sequence.syncing',
    'common.loader_sequence.ready',
  ];

  @override
  void initState() {
    super.initState();
    _displayMessage = widget.message ?? (widget.platform != null 
        ? 'common.loader_sequence.connecting'.tr(namedArgs: {'platform': widget.platform!})
        : 'common.loading'.tr());

    if (widget.platform != null) {
      _startSequence();
    }

    _delayTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showingDelay = true;
          _displayMessage = 'common.loader_sequence.delay'.tr();
        });
      }
    });
  }

  void _startSequence() {
    _sequenceTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
          if (!_showingDelay) {
            _displayMessage = _steps[_currentStep].tr(
              namedArgs: {'platform': widget.platform ?? ''},
            );
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
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
