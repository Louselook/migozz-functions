import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Servicio para gestionar el estado del tutorial en Firebase
class ProfileTutorialService {
  static const String _fieldName = 'tutorialComplete';

  /// Verifica si el usuario ya completó el tutorial
  /// Retorna true si ya lo completó o si hay un error (para no bloquear)
  static Future<bool> hasCompletedTutorial() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ [TutorialService] No hay usuario autenticado');
        return true; // No mostrar tutorial si no hay usuario
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ [TutorialService] Documento de usuario no existe');
        return false; // Mostrar tutorial si el documento no existe
      }

      final data = doc.data();
      final completed = data?[_fieldName] as bool? ?? false;

      debugPrint('✅ [TutorialService] Tutorial completado: $completed');
      return completed;
    } catch (e) {
      debugPrint('❌ [TutorialService] Error verificando tutorial: $e');
      return false; // En caso de error, intentar mostrar el tutorial
    }
  }

  /// Marca el tutorial como completado en Firebase
  static Future<void> markTutorialAsComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ [TutorialService] No se puede marcar: no hay usuario');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            {_fieldName: true},
            SetOptions(merge: true),
          );

      debugPrint('✅ [TutorialService] Tutorial marcado como completado: ${user.uid}');
    } catch (e) {
      debugPrint('❌ [TutorialService] Error marcando tutorial: $e');
    }
  }

  /// Resetea el estado del tutorial (para cuando el usuario quiere verlo de nuevo)
  /// NOTA: Esta función NO marca como incompleto en Firebase,
  /// solo permite que el tutorial se ejecute de nuevo localmente
  static Future<void> resetTutorialForReplay() async {
    debugPrint('🔄 [TutorialService] Tutorial reseteado para repetición local');
    // No modificamos Firebase, solo permitimos la reproducción local
  }
}
