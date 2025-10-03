import 'dart:io'; // 👈 No olvides este import para File
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_networks.dart';
// import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthService _authService;
  final LocationService _locationService;
  final UserMediaService _mediaService = UserMediaService();
  final AddNetworkService networkService = AddNetworkService();

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

  void updateLocation(LocationDTO? location) {
    emit(state.copyWith(location: location));
  }

  // ---------------------- Archivos temporales ----------------------
  void setAvatarFile(File file) => avatarFile = file;
  void setVoiceNoteFile(File file) => voiceNoteFile = file;

  void setAvatarUrl(String avatarUrl) =>
      emit(state.copyWith(avatarUrl: avatarUrl));
  void clearAvatarUrl() => emit(state.copyWith(avatarUrl: null));
  void setVoiceNoteUrl(String voiceNoteUrl) =>
      emit(state.copyWith(voiceNoteUrl: voiceNoteUrl));

  // ---------------------- Otros setters ----------------------
  void setEmail(String email) => emit(state.copyWith(email: email));
  void setFullName(String fullName) => emit(state.copyWith(fullName: fullName));
  void setPhone(String phone) => emit(state.copyWith(phone: phone));
  void setLanguage(String language) => emit(state.copyWith(language: language));
  void setUsername(String username) => emit(state.copyWith(username: username));
  void setGender(String gender) => emit(state.copyWith(gender: gender));
  void setSocialEcosystem(List<Map<String, Map<String, dynamic>>> platforms) =>
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

      Map<MediaType, String> mediaUrls = await _mediaService
          .uploadFilesTemporarily(email: state.email!, files: filesToUpload);

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
          state.interests != null; //&&
      // state.avatarUrl != null &&
      // state.voiceNoteUrl != null;

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
      if (state.avatarUrl != null)
        mediaUrls[MediaType.avatar] = state.avatarUrl!;
      if (state.voiceNoteUrl != null)
        mediaUrls[MediaType.voice] = state.voiceNoteUrl!;
      if (mediaUrls.isNotEmpty) {
        await _mediaService.associateMediaToUid(uid: uid, email: state.email!);
      }

      // 3️⃣ Guardar los perfiles sociales en la subcolección "socials"
      // if (state.userSocials != null && state.userSocials!.isNotEmpty) {
      //   for (final entry in state.userSocials!.entries) {
      //     final network = entry.key;
      //     final profile = entry.value;

      //     // Guardar cada perfil incluyendo URL
      //     await _authService.saveUserSocial(
      //       uid: uid,
      //       network: network,
      //       profile: profile,
      //     );
      //   }
      // }

      return uid;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    } finally {
      // Cambiar el estado a success aunque haya fallado la guardada de socials
      emit(state.copyWith(status: RegisterStatus.success));
    }
  }

  // ---------------------- fetch social profile ----------------------
  Future<void> fetchSocialProfile(String network, String usernameOrLink) async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      switch (network.toLowerCase()) {
        case 'instagram':
          await networkService.getInstagramProfile(
            usernameOrLink: usernameOrLink,
          );
          break;

        case 'youtube':
          await networkService.getYouTubeProfile(handleOrUrl: usernameOrLink);
          break;

        default:
          debugPrint("Red social no soportada: $network");
          return;
      }
    } catch (e) {
      debugPrint('Error fetching $network: $e');
    } finally {
      emit(state.copyWith(status: RegisterStatus.initial));
    }
  }

  Future<void> startSocialAuth(
    BuildContext context,
    String network,
    String assetPath,
  ) async {
    switch (network.toLowerCase()) {
      case 'instagram':
      case 'youtube':
        {
          await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddNetworkBottomSheet(
              label: network,
              assetPath: assetPath,
              onSaved: (value) async {
                LoadingOverlay.show(context);

                try {
                  // 1️⃣ Obtener los datos del perfil
                  Map<String, dynamic> profileData = {};
                  if (network.toLowerCase() == 'instagram') {
                    profileData = await networkService.getInstagramProfile(
                      usernameOrLink: value,
                    );
                  } else if (network.toLowerCase() == 'youtube') {
                    profileData = await networkService.getYouTubeProfile(
                      handleOrUrl: value,
                    );
                  }

                  // 2️⃣ Obtener la lista actual del cubit
                  final current = List<Map<String, Map<String, dynamic>>>.from(
                    state.socialEcosystem ?? [],
                  );

                  // 3️⃣ Agregar los datos en el formato correcto
                  current.add({network.toLowerCase(): profileData});

                  // 3.1️⃣ Si es Instagram y hay foto de perfil, usarla como avatar
                  if (network.toLowerCase() == 'instagram') {
                    final avatar =
                        (profileData['profile_picture_url'] ??
                                profileData['profilePicUrl'] ??
                                profileData['thumbnail_url'])
                            ?.toString();
                    if (avatar != null && avatar.isNotEmpty) {
                      setAvatarUrl(avatar);
                    }
                  }

                  // 4️⃣ Actualizar el cubit
                  setSocialEcosystem(current);
                } catch (e) {
                  debugPrint("❌ Error fetching $network profile: $e");
                } finally {
                  LoadingOverlay.hide(context);
                }

                Navigator.of(context).pop(value);
              },
            ),
          );

          debugPrint("✅ $network agregada: ${state.socialEcosystem}");
          break;
        }

      // OAuth2 se manejará aparte
      case 'twitter':
        await networkService.startTwitterAuth(context);
        break;
      case 'spotify':
        await networkService.startSpotifyAuth(context);
        break;
      case 'tiktok':
        await networkService.startTikTokAuth(context);
        break;

      default:
        debugPrint('Red social no soportada: $network');
    }
  }
}
