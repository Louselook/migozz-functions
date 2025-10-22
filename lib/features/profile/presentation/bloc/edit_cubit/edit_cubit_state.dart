part of 'edit_cubit_cubit.dart';

enum EditItem {
  empty,
  language,
  fullName,
  username,
  socialEcosystem,
  location,
  avatarUrl,
  phone,
  voiceNoteUrl,
  category,
  interests,
}

class EditCubitState extends Equatable {
  final EditItem editItem;
  final bool isSaving;
  final bool success;
  final String? error;
  final List<Map<String, dynamic>>? socialEcosystemEdit;

  const EditCubitState({
    this.editItem = EditItem.empty,
    this.isSaving = false,
    this.success = false,
    this.error,
    this.socialEcosystemEdit,
  });

  EditCubitState copyWith({
    EditItem? editItem,
    bool? isSaving,
    bool? success,
    String? error,
    final List<Map<String, dynamic>>? socialEcosystemEdit,
  }) {
    return EditCubitState(
      editItem: editItem ?? this.editItem,
      isSaving: isSaving ?? this.isSaving,
      success: success ?? this.success,
      error: error,
      socialEcosystemEdit: socialEcosystemEdit ?? this.socialEcosystemEdit,
    );
  }

  @override
  List<Object?> get props => [
    editItem,
    isSaving,
    success,
    error,
    socialEcosystemEdit,
  ];
}
