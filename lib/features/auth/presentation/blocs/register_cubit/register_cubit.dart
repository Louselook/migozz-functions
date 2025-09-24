import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  void setEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void setLanguage(String language) {
    emit(state.copyWith(language: language));
  }

  void setFullName(String fullName) {
    emit(state.copyWith(fullName: fullName));
  }

  void setUsername(String username) {
    emit(state.copyWith(username: username));
  }

  void setGender(String gender) {
    emit(state.copyWith(gender: gender));
  }

  void setSocialEcosystem(List<String> platforms) {
    emit(state.copyWith(socialEcosystem: platforms));
  }

  void setLocation(LocationDTO location) {
    emit(state.copyWith(location: location));
  }

  void setAvatarUrl(String avatarUrl) {
    emit(state.copyWith(avatarUrl: avatarUrl));
  }

  void setPhone(String phone) {
    emit(state.copyWith(phone: phone));
  }

  void setVoiceNoteUrl(String voiceNoteUrl) {
    emit(state.copyWith(voiceNoteUrl: voiceNoteUrl));
  }

  void setCategory(String category) {
    emit(state.copyWith(category: category));
  }

  void setInterests(Map<String, List<String>> interests) {
    emit(state.copyWith(interests: interests));
    // checkCompletion();
  }

  void updateEmailVerification(EmailVerification status) {
    emit(state.copyWith(emailVerification: status));
  }

  void toggleConfirmEmail() {
    emit(state.copyWith(confirmEmail: !state.confirmEmail));
  }

  // Validador - Podria validar en cada metodo
  void checkCompletion() {
    final complete =
        state.email != null &&
        state.language != null &&
        state.fullName != null &&
        state.username != null &&
        state.gender != null &&
        state.location != null &&
        state.avatarUrl != null &&
        state.phone != null &&
        state.voiceNoteUrl != null &&
        state.category != null &&
        state.interests != null;

    if (state.isComplete != complete) {
      emit(state.copyWith(isComplete: complete));
    }
  }
}
