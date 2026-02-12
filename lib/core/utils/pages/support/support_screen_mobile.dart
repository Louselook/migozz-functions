// lib/core/utils/pages/support/support_screen_mobile.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInBrowser();
    });
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://migozz-e2a21.web.app/support');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          context.go('/login');
        }
      } else {
        if (mounted) {
          AlertGeneral.show(context, 4, message: 'Could not open support page');
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('Error opening browser: $e');
      if (mounted) {
        AlertGeneral.show(context, 4, message: 'Error: $e');
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: LoaderDialog(message: 'Opening support page in browser...'),
      ),
    );
  }
}
