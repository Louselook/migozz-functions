import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/tutorial/profile_tutorial.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

/// Verifica si el usuario ya completó el tutorial
Future<bool> hasCompletedTutorial() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No hay usuario autenticado');
      return true; // No mostrar tutorial si no hay usuario
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      debugPrint('⚠️ Documento de usuario no existe');
      return false; // Mostrar tutorial si el documento no existe
    }

    final data = doc.data();
    final completed = data?['tutorialComplete'] as bool? ?? false;
    
    debugPrint('✅ Tutorial completado: $completed');
    return completed;
  } catch (e) {
    debugPrint('❌ Error verificando tutorial: $e');
    return false; // En caso de error, mostrar el tutorial
  }
}

/// Marca el tutorial como completado en Firebase
Future<void> markTutorialAsComplete() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No se puede marcar tutorial: no hay usuario autenticado');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
          {'tutorialComplete': true},
          SetOptions(merge: true), // Merge para no sobrescribir otros campos
        );

    debugPrint('✅ Tutorial marcado como completado para usuario: ${user.uid}');
  } catch (e) {
    debugPrint('❌ Error marcando tutorial como completado: $e');
  }
}

/// Espera hasta que un widget con la [key] haya sido montado en el árbol.
Future<void> waitForKey(GlobalKey key, {int maxRetries = 30}) async {
  int retries = 0;
  while (key.currentContext == null && retries < maxRetries) {
    await Future.delayed(const Duration(milliseconds: 100));
    retries++;
  }

  if (key.currentContext == null) {
    debugPrint('⚠️ Key no encontrado después de $maxRetries intentos');
  } else {
    debugPrint('✅ Key encontrado: ${key.toString()}');
  }
}

/// Muestra el tutorial del perfil una vez los elementos están listos.
/// Verifica primero si el usuario ya completó el tutorial.
Future<void> triggerProfileTutorial(
  BuildContext context,
  TutorialKeys tutorialKeys,
) async {
  debugPrint('🎓 Verificando estado del tutorial...');

  // 1. Verificar si ya completó el tutorial
  final alreadyCompleted = await hasCompletedTutorial();
  if (alreadyCompleted) {
    debugPrint('Tutorial ya fue completado, saltando...');
    return; // No mostrar el tutorial
  }

  debugPrint('🎓 Iniciando espera de keys para tutorial...');

  // 2. Esperar a que todos los keys estén listos
  await Future.wait([
    waitForKey(tutorialKeys.searchScreenKey),
    waitForKey(tutorialKeys.playButtonKey),
    waitForKey(tutorialKeys.shareButtonKey),
    waitForKey(tutorialKeys.profileScreenKey),
    waitForKey(tutorialKeys.statScreenKey),
    waitForKey(tutorialKeys.editScreenKey),
  ]);

  // Delay adicional para asegurar renderizado completo
  await Future.delayed(const Duration(milliseconds: 500));

  if (!context.mounted) {
    debugPrint('⚠️ Context ya no está montado, cancelando tutorial');
    return;
  }

  debugPrint('🎓 Mostrando tutorial...');

  // 3. Mostrar el tutorial con callback al finalizar
  ProfileTutorial.showTutorial(
    context,
    tutorialKeys,
    onFinish: () async {
      debugPrint('🎉 Tutorial finalizado, guardando estado...');
      await markTutorialAsComplete();
    },
  );
}