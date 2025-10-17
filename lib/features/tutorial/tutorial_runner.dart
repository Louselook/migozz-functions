import 'dart:async';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

/// Espera hasta que todos los keys del tutorial tengan context válido
Future<void> waitForAllKeys(TutorialKeys keys,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    final allLoaded = [
      keys.searchScreenKey,
      keys.playButtonKey,
      keys.shareButtonKey,
      keys.profileScreenKey,
      keys.statScreenKey,
      keys.editScreenKey,
    ].every((k) => k.currentContext != null);

    if (allLoaded) {
      debugPrint('✅ Todos los widgets listos para tutorial');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  debugPrint('⚠️ Algunos widgets no aparecieron antes del timeout');
}
