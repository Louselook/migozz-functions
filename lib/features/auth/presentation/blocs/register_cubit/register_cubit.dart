import 'dart:io'; // 👈 No olvides este import para File
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthService _authService;
  final LocationService _locationService;
  final UserMediaService _mediaService = UserMediaService();

  File? avatarFile;
  File? voiceNoteFile;

  RegisterCubit(this._authService, this._locationService)
    : super(const RegisterState()) {
    fetchLocation(); // 👈 Debe ir dentro de las llaves
  }

  // Método para obtener ubicación
  Future<void> fetchLocation() async {
    final location = await _locationService.initAndFetchAddress();
    if (location != null) {
      emit(state.copyWith(location: location));
    }
  }

  // ---------------------- Archivos temporales ----------------------
  void setAvatarFile(File file) => avatarFile = file;
  void setVoiceNoteFile(File file) => voiceNoteFile = file;

  void setAvatarUrl(String avatarUrl) =>
      emit(state.copyWith(avatarUrl: avatarUrl));
  void setVoiceNoteUrl(String voiceNoteUrl) =>
      emit(state.copyWith(voiceNoteUrl: voiceNoteUrl));

  // ---------------------- Otros setters ----------------------
  void setEmail(String email) => emit(state.copyWith(email: email));
  void setFullName(String fullName) => emit(state.copyWith(fullName: fullName));
  void setPhone(String phone) => emit(state.copyWith(phone: phone));
  void setLanguage(String language) => emit(state.copyWith(language: language));
  void setUsername(String username) => emit(state.copyWith(username: username));
  void setGender(String gender) => emit(state.copyWith(gender: gender));
  void setSocialEcosystem(List<String> platforms) =>
      emit(state.copyWith(socialEcosystem: platforms));
  void setLocation(LocationDTO location) =>
      emit(state.copyWith(location: location));
  void setCategories(List<String>? category) =>
      emit(state.copyWith(category: category));
  void setInterests(Map<String, List<String>> interests) =>
      emit(state.copyWith(interests: interests));
  void updateEmailVerification(EmailVerification status) =>
      emit(state.copyWith(emailVerification: status));
  void setCurrentOTP(String currentOTP) =>
      emit(state.copyWith(currentOTP: currentOTP));

  // ---------------------- checkCompletion ----------------------
  Future<void> checkCompletion() async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      final Map<MediaType, File> filesToUpload = {};
      if (avatarFile != null) filesToUpload[MediaType.avatar] = avatarFile!;
      if (voiceNoteFile != null) {
        filesToUpload[MediaType.voice] = voiceNoteFile!;
      }

      Map<MediaType, String> mediaUrls = {};
      mediaUrls = await _mediaService.uploadFilesTemporarily(
        email: state.email!,
        files: filesToUpload,
      );

      // Guardar URLs en el cubit inmediatamente
      if (mediaUrls.containsKey(MediaType.avatar)) {
        setAvatarUrl(mediaUrls[MediaType.avatar]!);
      }
      if (mediaUrls.containsKey(MediaType.voice)) {
        setVoiceNoteUrl(mediaUrls[MediaType.voice]!);
      }

      // 2️⃣ Validar completitud incluyendo archivos
      final complete =
          state.email != null &&
          state.language != null &&
          state.fullName != null &&
          state.username != null &&
          state.gender != null &&
          state.location != null &&
          state.phone != null &&
          state.category != null &&
          state.interests != null &&
          state.avatarUrl != null &&
          state.voiceNoteUrl != null;

      if (state.isComplete != complete) {
        emit(state.copyWith(isComplete: complete));
        // Solo llamas al método final de registro
        completeRegistration();
      }
    } catch (e) {}
  }

  // ---------------------- completeRegistration ----------------------
  Future<String?> completeRegistration() async {
    try {
      if (!state.isComplete) {
        throw Exception('Faltan datos para completar el registro');
      }

      final userDTO = state.buildUserDTO();

      // 1️⃣ Crear usuario en Auth y Firestore
      final userCredential = await _authService.signUpRegister(
        email: state.email!,
        otp: state.currentOTP!,
        userData: userDTO,
      );

      final uid = userCredential.user!.uid;

      // 2️⃣ Asociar archivos subidos temporalmente al UID definitivo
      final Map<MediaType, String> mediaUrls = {};
      if (state.avatarUrl != null) {
        mediaUrls[MediaType.avatar] = state.avatarUrl!;
      }
      if (state.voiceNoteUrl != null) {
        mediaUrls[MediaType.voice] = state.voiceNoteUrl!;
      }
      if (mediaUrls.isNotEmpty) {
        await _mediaService.associateMediaToUid(uid: uid, email: state.email!);
      }

      return uid;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    } finally {
      emit(state.copyWith(status: RegisterStatus.success));
    }
  }
}
