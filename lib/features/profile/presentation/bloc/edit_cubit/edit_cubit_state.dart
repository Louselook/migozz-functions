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

  /// Datos temporales para edición (antes de guardar)
  final List<Map<String, dynamic>>? socialEcosystem;
  final List<String>? category;
  final Map<String, List<String>>? interests;

  const EditCubitState({
    this.editItem = EditItem.empty,
    this.isSaving = false,
    this.success = false,
    this.error,
    this.socialEcosystem,
    this.category,
    this.interests,
  });

  EditCubitState copyWith({
    EditItem? editItem,
    bool? isSaving,
    bool? success,
    String? error,
    List<Map<String, dynamic>>? socialEcosystem,
    List<String>? category,
    Map<String, List<String>>? interests,
  }) {
    return EditCubitState(
      editItem: editItem ?? this.editItem,
      isSaving: isSaving ?? this.isSaving,
      success: success ?? this.success,
      error: error,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,
      category: category ?? this.category,
      interests: interests ?? this.interests,
    );
  }

  @override
  List<Object?> get props => [
    editItem,
    isSaving,
    success,
    error,
    socialEcosystem,
    category,
    interests,
  ];
}
