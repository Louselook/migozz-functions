import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
part 'edit_cubit_state.dart';

class EditCubit extends Cubit<EditCubitState> {
  final UserService _userService;
  final AuthCubit _authCubit;

  EditCubit(this._userService, this._authCubit) : super(const EditCubitState());

  /// Cambiar el campo activo que se está editando
  void setEditItem(EditItem item) => emit(state.copyWith(editItem: item));

  // Inicializar datos desde el usuario actual para edición
  void initializeFromUser({
    List<Map<String, dynamic>>? socialEcosystem,
    List<String>? category,
    Map<String, List<String>>? interests,
  }) {
    // Cuando inicializamos desde el usuario, no hay cambios pendientes
    emit(
      state.copyWith(
        socialEcosystem: socialEcosystem ?? [],
        category: category ?? [],
        interests: interests ?? {},
        hasChanges: false,
      ),
    );
  }

  // Actualizar social ecosystem temporalmente
  void updateSocialEcosystem(List<Map<String, dynamic>> socials) {
    debugPrint('📝 [EditCubit] updateSocialEcosystem called');
    debugPrint('📝 [EditCubit] New socials count: ${socials.length}');
    debugPrint('📝 [EditCubit] New socials: $socials');

    // Marca cambios (simple): cuando el usuario modifica la lista
    emit(state.copyWith(socialEcosystem: socials, hasChanges: true));

    debugPrint('✅ [EditCubit] State updated, hasChanges: true');
  }

  // Actualizar categorías temporalmente
  void updateCategory(List<String> categories) {
    emit(state.copyWith(category: categories, hasChanges: true));
  }

  // Actualizar intereses temporalmente
  void updateInterests(Map<String, List<String>> interests) {
    emit(state.copyWith(interests: interests, hasChanges: true));
  }

  // Guardar cambios del usuario (campo específico)
  Future<void> saveUserProfileField({
    required String userId,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      emit(state.copyWith(isSaving: true));

      await _userService.updateUserProfile(userId, updatedFields);

      //  Refresca el AuthCubit automáticamente
      await _authCubit.refreshUserProfile();

      // Al guardar, no quedan cambios pendientes
      emit(state.copyWith(isSaving: false, success: true, hasChanges: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  // Guardar todos los cambios pendientes (socialEcosystem, category, interests)
  Future<void> saveAllPendingChanges(String userId) async {
    try {
      emit(state.copyWith(isSaving: true));

      final Map<String, dynamic> updates = {};

      Set<String> extractPlatforms(List<Map<String, dynamic>> socials) {
        final out = <String>{};
        for (final entry in socials) {
          // Formato A: { platform: 'instagram', username: 'x', ... }
          final p = entry['platform'];
          if (p is String && p.trim().isNotEmpty) {
            out.add(p.trim().toLowerCase());
            continue;
          }

          // Formato B: { instagram: { ... } }
          for (final k in entry.keys) {
            if (k.trim().isNotEmpty) out.add(k.trim().toLowerCase());
          }
        }
        return out;
      }

      if (state.socialEcosystem != null) {
        updates['socialEcosystem'] = state.socialEcosystem;

        // Mantener fechas de agregado por plataforma (para job por-red)
        final currentProfile = _authCubit.state.userProfile;
        final existingAdded =
            currentProfile?.socialEcosystemAddedDates ?? <String, DateTime>{};

        final oldPlatforms = currentProfile?.socialEcosystem != null
            ? extractPlatforms(currentProfile!.socialEcosystem!)
            : <String>{};
        final newPlatforms = extractPlatforms(state.socialEcosystem!);

        final Map<String, dynamic> nextAddedDates = {
          for (final e in existingAdded.entries) e.key.toLowerCase(): e.value,
        };

        for (final platform in newPlatforms) {
          if (nextAddedDates.containsKey(platform)) continue;
          // Plataforma nueva -> timestamp server para que el backend compute días correctamente
          nextAddedDates[platform] = FieldValue.serverTimestamp();
        }

        // Solo escribir si hubo cambios reales (nuevo agregado)
        if (newPlatforms.difference(oldPlatforms).isNotEmpty) {
          updates['socialEcosystemAddedDates'] = nextAddedDates;
        }
      }
      if (state.category != null && state.category!.isNotEmpty) {
        updates['category'] = state.category;
      }
      if (state.interests != null && state.interests!.isNotEmpty) {
        updates['interests'] = state.interests;
      }

      if (updates.isNotEmpty) {
        await _userService.updateUserProfile(userId, updates);
        await _authCubit.refreshUserProfile();
      }

      // Reset hasChanges al finalizar exitosamente
      emit(state.copyWith(isSaving: false, success: true, hasChanges: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  /// actualizar avatar
  /// Returns true if avatar was changed, false if user cancelled
  Future<bool> changeAvatar(String userId, BuildContext context) async {
    try {
      emit(state.copyWith(isSaving: true));
      final newUrl = await _userService.changeAvatar(userId, context);

      if (newUrl != null) {
        await _authCubit.refreshUserProfile();
        emit(state.copyWith(isSaving: false, success: true));
        return true;
      }

      // User cancelled - no image selected
      emit(state.copyWith(isSaving: false));
      return false;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
      rethrow;
    }
  }

  /// Limpiar estado
  void reset() {
    emit(EditCubitState.initial());
    debugPrint('✅ [EditCubit] Estado reseteado');
  }
}
