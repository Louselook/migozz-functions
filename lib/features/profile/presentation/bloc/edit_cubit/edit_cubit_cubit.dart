import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

      if (state.socialEcosystem != null) {
        updates['socialEcosystem'] = state.socialEcosystem;
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
  Future<void> changeAvatar(String userId) async {
    try {
      emit(state.copyWith(isSaving: true));
      final newUrl = await _userService.changeAvatar(userId);

      if (newUrl != null) {
        await _authCubit.refreshUserProfile();
      }

      emit(state.copyWith(isSaving: false, success: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  /// Limpiar estado
  void clear() => emit(const EditCubitState());
}
