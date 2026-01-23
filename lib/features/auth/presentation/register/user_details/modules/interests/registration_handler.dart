import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class RegistrationHandler {
  // Completa el registro según el tipo de autenticación
  static Future<void> completeRegistration({
    required BuildContext context,
    required RegisterCubit registerCubit,
    required AuthCubit authCubit,
  }) async {
    debugPrint('▶️ [RegistrationHandler] Iniciando completeRegistration...');
    debugPrint(
      '   - auth isAuthenticated=${authCubit.state.isAuthenticated} '
      'firebaseUser=${authCubit.state.firebaseUser?.uid}',
    );
    debugPrint(
      '   - register snapshot: isComplete=${registerCubit.state.isComplete} '
      'email=${registerCubit.state.email} fullName=${registerCubit.state.fullName} '
      'voiceNoteUrl=${registerCubit.state.voiceNoteUrl} avatarUrl=${registerCubit.state.avatarUrl}',
    );

    // Verificar si está autenticado con un proveedor social (Google o Apple)
    final firebaseUser = authCubit.state.firebaseUser;
    final isSocialAuthUser =
        authCubit.state.isAuthenticated && firebaseUser != null;

    debugPrint('🔍 [RegistrationHandler] isSocialAuthUser: $isSocialAuthUser');
    debugPrint('🔍 [RegistrationHandler] UID: ${firebaseUser?.uid}');

    // Verificar completitud pasando el UID si está disponible
    await registerCubit.checkCompletion(
      forGoogle: isSocialAuthUser,
      uid: isSocialAuthUser ? firebaseUser.uid : null,
    );

    // Si no está completo, mostrar error y listar campos faltantes
    if (!registerCubit.state.isComplete) {
      debugPrint(
        '⚠️ [RegistrationHandler] Registro incompleto tras checkCompletion. Estado completo? ${registerCubit.state.isComplete}',
      );
      final missing = <String>[];
      final s = registerCubit.state;
      if (s.email == null || (s.email as String).trim().isEmpty) {
        missing.add('email');
      }
      if (s.fullName == null || (s.fullName as String).trim().isEmpty) {
        missing.add('fullName');
      }
      if (s.username == null || (s.username as String).trim().isEmpty) {
        missing.add('username');
      }
      if (s.voiceNoteUrl == null || (s.voiceNoteUrl as String).trim().isEmpty) {
        missing.add('voiceNoteUrl');
      }
      if (s.avatarUrl == null || (s.avatarUrl as String).trim().isEmpty) {
        missing.add('avatarUrl');
      }
      if (s.location == null) missing.add('location');
      debugPrint('   -> Campos faltantes: ${missing.join(", ")}');

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

    // Proceder con el registro según el flujo
    try {
      if (!context.mounted) return;
      LoadingOverlay.show(context);

      if (isSocialAuthUser) {
        // firebaseUser ya no es null porque isSocialAuthUser es true
        await _completeSocialAuthRegistration(
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
    } catch (e, st) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completando registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ [RegistrationHandler] Error: $e\n$st');
      rethrow;
    }
  }

  /// Completa el registro para usuarios autenticados con proveedor social (Google o Apple)
  static Future<void> _completeSocialAuthRegistration({
    required BuildContext context,
    required RegisterCubit registerCubit,
    required AuthCubit authCubit,
    required String uid,
  }) async {
    debugPrint('🔵 [RegistrationHandler] Flujo Social Auth (Google/Apple) iniciado');

    final Map<String, dynamic> updateData = {};

    Set<String> extractPlatformsFromSocialEcosystem(
      List<Map<String, dynamic>> socials,
    ) {
      final out = <String>{};
      for (final entry in socials) {
        final p = entry['platform'];
        if (p is String && p.trim().isNotEmpty) {
          out.add(p.trim().toLowerCase());
          continue;
        }

        for (final k in entry.keys) {
          if (k.trim().isNotEmpty) out.add(k.trim().toLowerCase());
        }
      }
      return out;
    }

    if (registerCubit.state.language != null) {
      updateData['lang'] = registerCubit.state.language;
    }
    if (registerCubit.state.fullName != null) {
      updateData['displayName'] = registerCubit.state.fullName;
    }
    if (registerCubit.state.username != null) {
      updateData['username'] = registerCubit.state.username;
    }
    // if (registerCubit.state.gender != null) {
    //   updateData['gender'] = registerCubit.state.gender;
    // }

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

    if (registerCubit.state.socialEcosystem != null &&
        registerCubit.state.socialEcosystem!.isNotEmpty) {
      updateData['socialEcosystem'] = registerCubit.state.socialEcosystem;

      // ✅ Guardar fechas de agregado por plataforma (para job por-red)
      // - Mantiene valores existentes si ya están
      // - Agrega serverTimestamp() solo a plataformas nuevas
      final currentProfile = authCubit.state.userProfile;
      final existingAdded =
          currentProfile?.socialEcosystemAddedDates ?? <String, DateTime>{};

      final existingMap = <String, dynamic>{
        for (final e in existingAdded.entries) e.key.toLowerCase(): e.value,
      };

      final platforms = extractPlatformsFromSocialEcosystem(
        registerCubit.state.socialEcosystem!,
      );

      for (final platform in platforms) {
        if (existingMap.containsKey(platform)) continue;
        existingMap[platform] = FieldValue.serverTimestamp();
      }

      updateData['socialEcosystemAddedDates'] = existingMap;
    }

    if (registerCubit.state.avatarUrl != null) {
      updateData['avatarUrl'] = registerCubit.state.avatarUrl;
    }
    if (registerCubit.state.voiceNoteUrl != null) {
      updateData['voiceNoteUrl'] = registerCubit.state.voiceNoteUrl;
    }

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

    updateData['complete'] = true;
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      debugPrint('✅ [RegistrationHandler] Firestore actualizado');

      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      // Actualizar estados (esto dispara la redirección del router)
      await authCubit.refreshUserProfile();
      registerCubit.reset();

      debugPrint('🎉 [RegistrationHandler] Flujo Social Auth completado');
    } catch (e, st) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      debugPrint('❌ [RegistrationHandler] Error en flujo Social Auth: $e\n$st');
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

    final email = registerCubit.state.email;
    final otp = registerCubit.state.currentOTP;
    final isPreRegistered = registerCubit.state.isPreRegistered;
    final preOrderId = registerCubit.state.preOrderId;

    debugPrint('🟢 [RegistrationHandler] Email: $email');
    debugPrint('🟢 [RegistrationHandler] OTP: $otp');
    debugPrint('🟢 [RegistrationHandler] isPreRegistered: $isPreRegistered');
    debugPrint('🟢 [RegistrationHandler] preOrderId: $preOrderId');

    if (email == null || email.trim().isEmpty) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email faltante.')));
      }
      throw StateError('Email faltante en registerCubit.state.email');
    }
    if (otp == null || otp.trim().isEmpty) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP faltante.')));
      }
      throw StateError('OTP faltante en registerCubit.state.currentOTP');
    }

    try {
      String uid;

      // ✅ Si es pre-registrado, primero eliminar el documento pre-order
      // para evitar conflictos de email/UID, luego registrar normalmente
      if (isPreRegistered && preOrderId != null) {
        debugPrint(
          '🗑️ [RegistrationHandler] Eliminando pre-order $preOrderId antes de registrar...',
        );

        final deleteSuccess = await registerCubit.deletePreOrder();
        if (!deleteSuccess) {
          debugPrint('❌ [RegistrationHandler] No se pudo eliminar pre-order');
          throw Exception('Error eliminando documento pre-order');
        }
        debugPrint(
          '✅ [RegistrationHandler] Pre-order eliminado, procediendo con registro normal...',
        );
      }

      // 🆕 FLUJO NORMAL para todos los usuarios:
      // Crear usuario Auth + documento Firestore
      debugPrint('🆕 [RegistrationHandler] Registrando usuario...');

      uid = await authCubit.completeRegistration(
        email: email,
        otp: otp,
        userData: registerCubit.state.buildUserDTO(),
      );
      debugPrint('✅ [RegistrationHandler] Usuario creado con UID: $uid');

      // Resetear el cubit
      registerCubit.reset();

      // Esperar propagación del estado
      await Future.delayed(const Duration(milliseconds: 150));

      // Refrescar perfil (dispara redirección del router)
      await authCubit.refreshUserProfile();

      // Ocultar loading
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      debugPrint('🎉 [RegistrationHandler] Flujo Email/OTP completado');
    } catch (e, st) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      debugPrint('❌ [RegistrationHandler] Error en flujo Email/OTP: $e\n$st');
      rethrow;
    }
  }
}
