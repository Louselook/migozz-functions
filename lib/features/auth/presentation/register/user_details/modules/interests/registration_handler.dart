import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class RegistrationHandler {
  /// Completa el registro según el tipo de autenticación
  static Future<void> completeRegistration({
    required BuildContext context,
    required RegisterCubit registerCubit,
    required AuthCubit authCubit,
    required Map<String, List<String>> selectedInterests,
  }) async {
    // 1️⃣ Guardar intereses en el cubit
    registerCubit.setInterests(selectedInterests);

    // 2️⃣ Verificar si está autenticado con Google
    final firebaseUser = authCubit.state.firebaseUser;
    final isAuthWithGoogle =
        authCubit.state.isAuthenticated && firebaseUser != null;

    debugPrint('🔍 [RegistrationHandler] isAuthWithGoogle: $isAuthWithGoogle');
    debugPrint('🔍 [RegistrationHandler] UID: ${firebaseUser?.uid}');

    // 3️⃣ Verificar completitud pasando el UID si está disponible
    await registerCubit.checkCompletion(
      forGoogle: isAuthWithGoogle,
      uid: isAuthWithGoogle ? firebaseUser.uid : null, // 👈 Pasar UID
    );

    // 4️⃣ Si no está completo, mostrar error
    if (!registerCubit.state.isComplete) {
      debugPrint('⚠ [RegistrationHandler] Registro incompleto');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faltan datos para completar el registro'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 5️⃣ Proceder con el registro según el flujo
    try {
      if (!context.mounted) return;
      LoadingOverlay.show(context);

      if (isAuthWithGoogle) {
        await _completeGoogleRegistration(
          context: context,
          registerCubit: registerCubit,
          authCubit: authCubit,
          uid: firebaseUser.uid,
        );
      } else {
        await _completeEmailRegistration(
          context: context,
          registerCubit: registerCubit,
          authCubit: authCubit,
        );
      }
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completando registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ [RegistrationHandler] Error: $e');
    }
  }

  /// Completa el registro para usuarios autenticados con Google
  static Future<void> _completeGoogleRegistration({
    required BuildContext context,
    required RegisterCubit registerCubit,
    required AuthCubit authCubit,
    required String uid,
  }) async {
    debugPrint('🔵 [RegistrationHandler] Flujo Google iniciado');

    // Construir datos para actualizar en Firestore
    final Map<String, dynamic> updateData = {};

    if (registerCubit.state.language != null) {
      updateData['lang'] = registerCubit.state.language;
    }
    if (registerCubit.state.fullName != null) {
      updateData['displayName'] = registerCubit.state.fullName;
    }
    if (registerCubit.state.username != null) {
      updateData['username'] = registerCubit.state.username;
    }
    if (registerCubit.state.gender != null) {
      updateData['gender'] = registerCubit.state.gender;
    }

    // Location
    final loc = registerCubit.state.location;
    if (loc != null) {
      updateData['location'] = {
        'country': loc.country,
        'state': loc.state,
        'city': loc.city,
        'lat': loc.lat,
        'lng': loc.lng,
      };
    }

    // Social ecosystem
    if (registerCubit.state.socialEcosystem != null &&
        registerCubit.state.socialEcosystem!.isNotEmpty) {
      updateData['socialEcosystem'] = registerCubit.state.socialEcosystem;
    }

    // 🎯 URLs de media (ya vienen con UID correcto desde checkCompletion)
    if (registerCubit.state.avatarUrl != null) {
      updateData['avatarUrl'] = registerCubit.state.avatarUrl;
    }
    if (registerCubit.state.voiceNoteUrl != null) {
      updateData['voiceNoteUrl'] = registerCubit.state.voiceNoteUrl;
    }

    // Otros datos
    if (registerCubit.state.phone != null) {
      updateData['phone'] = registerCubit.state.phone;
    }
    if (registerCubit.state.category != null &&
        registerCubit.state.category!.isNotEmpty) {
      updateData['category'] = registerCubit.state.category;
    }
    if (registerCubit.state.interests != null &&
        registerCubit.state.interests!.isNotEmpty) {
      updateData['interests'] = registerCubit.state.interests;
    }

    // Marcar como completo
    updateData['complete'] = true;
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    try {
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      debugPrint('✅ [RegistrationHandler] Firestore actualizado');

      // Ocultar loading ANTES de cambiar estados
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      // Actualizar estados (esto dispara la redirección del router)
      await authCubit.refreshUserProfile();
      registerCubit.reset();

      debugPrint('🎉 [RegistrationHandler] Flujo Google completado');
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      debugPrint('❌ [RegistrationHandler] Error en flujo Google: $e');
      rethrow;
    }
  }

  /// Completa el registro para usuarios con Email/OTP
  static Future<void> _completeEmailRegistration({
    required BuildContext context,
    required RegisterCubit registerCubit,
    required AuthCubit authCubit,
  }) async {
    debugPrint('🟢 [RegistrationHandler] Flujo Email/OTP iniciado');

    try {
      // 1️⃣ Completar registro en backend
      await authCubit.completeRegistration(
        email: registerCubit.state.email!,
        otp: registerCubit.state.currentOTP!,
        userData: registerCubit.state.buildUserDTO(),
      );

      // 2️⃣ Resetear el cubit
      registerCubit.reset();

      // 3️⃣ Esperar propagación del estado
      await Future.delayed(const Duration(milliseconds: 150));

      // 4️⃣ Refrescar perfil (dispara redirección del router)
      await authCubit.refreshUserProfile();

      // 5️⃣ Ocultar loading
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      debugPrint('🎉 [RegistrationHandler] Flujo Email/OTP completado');
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      debugPrint('❌ [RegistrationHandler] Error en flujo Email/OTP: $e');
      rethrow;
    }
  }
}