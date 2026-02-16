import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TranslationDebugWidget extends StatelessWidget {
  const TranslationDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Locale: ${context.locale}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'web.menu.search'.tr(),
              style: const TextStyle(color: Colors.green, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'web.menu.profile'.tr(),
              style: const TextStyle(color: Colors.green, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'web.chat.title'.tr(),
              style: const TextStyle(color: Colors.green, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              'stats.title'.tr(),
              style: const TextStyle(color: Colors.blue, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
