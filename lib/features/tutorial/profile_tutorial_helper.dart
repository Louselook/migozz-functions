// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:migozz_app/features/tutorial/profile_tutorial.dart';
// import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

// /// Verifica si el usuario ya completó el tutorial
// Future<bool> hasCompletedTutorial() async {
//   try {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('⚠️ No hay usuario autenticado');
//       return true; // No mostrar tutorial si no hay usuario
//     }

//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();

//     if (!doc.exists) {
//       debugPrint('⚠️ Documento de usuario no existe');
//       return false; // Mostrar tutorial si el documento no existe
//     }

//     final data = doc.data();
//     final completed = data?['tutorialComplete'] as bool? ?? false;

//     debugPrint('✅ Tutorial completado: $completed');
//     return completed;
//   } catch (e) {
//     debugPrint('❌ Error verificando tutorial: $e');
//     return false; // En caso de error, mostrar el tutorial
//   }
// }

// /// Marca el tutorial como completado en Firebase
// Future<void> markTutorialAsComplete() async {
//   try {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('⚠️ No se puede marcar tutorial: no hay usuario autenticado');
//       return;
//     }

//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .set(
//           {'tutorialComplete': true},
//           SetOptions(merge: true), // Merge para no sobrescribir otros campos
//         );

//     debugPrint('✅ Tutorial marcado como completado para usuario: ${user.uid}');
//   } catch (e) {
//     debugPrint('❌ Error marcando tutorial como completado: $e');
//   }
// }

// /// Espera hasta que un widget con la [key] haya sido montado en el árbol.
// /// Devuelve true si se encontró, false si no (después de timeout).
// Future<bool> waitForKey(GlobalKey key, {int maxRetries = 60}) async {
//   int retries = 0;
//   while (key.currentContext == null && retries < maxRetries) {
//     await Future.delayed(const Duration(milliseconds: 100));
//     retries++;
//   }

//   if (key.currentContext == null) {
//     debugPrint('⚠️ Key no encontrado después de $maxRetries intentos: ${key.toString()}');
//     return false;
//   } else {
//     debugPrint('✅ Key encontrado: ${key.toString()}');
//     return true;
//   }
// }

// /// Muestra el tutorial del perfil una vez los elementos están listos.
// /// Esta versión:
// ///  - espera cada key individualmente (secuencial)
// ///  - registra qué keys están disponibles
// ///  - llama al tutorial con UN subconjunto de targets (solo los montados)
// Future<void> triggerProfileTutorial(
//   BuildContext context,
//   TutorialKeys tutorialKeys, {
//   int initialDelayMs = 200,
//   int perKeyRetries = 30,
// }) async {
//   debugPrint('🎓 Verificando estado del tutorial...');

//   final alreadyCompleted = await hasCompletedTutorial();
//   if (alreadyCompleted) {
//     debugPrint('🎓 Tutorial ya completado; no se mostrará.');
//     return;
//   }

//   // Pequeño delay inicial para dejar que la pantalla arranque.
//   await Future.delayed(Duration(milliseconds: initialDelayMs));

//   // Lista de pares: nombre amigable + key
//   final keyPairs = <String, GlobalKey>{
//     'search': tutorialKeys.searchScreenKey,
//     'play': tutorialKeys.playButtonKey,
//     'share': tutorialKeys.shareButtonKey,
//     'profile': tutorialKeys.profileScreenKey,
//     'stat': tutorialKeys.statScreenKey,
//     'edit': tutorialKeys.editScreenKey,
//   };

//   // Intentamos esperar cada key, y registramos cuáles se encontraron.
//   final Map<String, bool> found = {};
//   for (final entry in keyPairs.entries) {
//     final name = entry.key;
//     final key = entry.value;
//     // Si el key ya tiene contexto al inicio, no esperamos.
//     if (key.currentContext != null) {
//       debugPrint('🔎 Key "$name" ya montada: ${key.toString()}');
//       found[name] = true;
//       continue;
//     }

//     // Esperar hasta perKeyRetries (más corto que antes)
//     final ok = await waitForKey(key, maxRetries: perKeyRetries);
//     found[name] = ok;
//   }

//   // Mostrar resumen
//   debugPrint('📋 Keys encontradas summary: ${found.map((k, v) => MapEntry(k, v ? "OK" : "missing"))}');

//   // Si ninguna key fue encontrada, abortamos con log claro
//   final anyFound = found.values.any((v) => v == true);
//   if (!anyFound) {
//     debugPrint('⚠️ Ningún target del tutorial montado. Abortando tutorial.');
//     return;
//   }

//   // Esperar un frame extra y un pequeño delay para estabilizar layout
//   await Future.delayed(const Duration(milliseconds: 150));
//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     if (!context.mounted) return;

//     debugPrint('🎓 Mostrando tutorial con keys encontradas...');
//     ProfileTutorial.showTutorial(
//       context,
//       tutorialKeys,
//       includedTargets: found, // pasamos mapa para que el tutorial filtre targets
//       onFinish: () async {
//         await markTutorialAsComplete();
//       },
//     );
//   });
// }
