import 'dart:io'; // 👈 No olvides este import para File
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_detail_step.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_networks.dart';
import 'package:migozz_app/features/auth/services/add_networks/profile_data.dart';
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
      if (state.userSocials != null && state.userSocials!.isNotEmpty) {
        for (final entry in state.userSocials!.entries) {
          final network = entry.key;
          final profile = entry.value;

          // Guardar cada perfil incluyendo URL
          await _authService.saveUserSocial(
            uid: uid,
            network: network,
            profile: profile,
          );
        }
      }

      return uid;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    } finally {
      // Cambiar el estado a success aunque haya fallado la guardada de socials
      emit(state.copyWith(status: RegisterStatus.success));
    }
  }

  // ---------------------- add socials ----------------------
  void addUserSocial(String network, ProfileData profile) {
    // Crear copia del mapa actual para no modificar el estado directamente
    final current = Map<String, ProfileData>.from(state.userSocials ?? {});

    // Guardar o actualizar la red social (incluye url)
    current[network] = profile;

    // Emitir nuevo estado con el mapa actualizado
    emit(state.copyWith(userSocials: current));
  }

  // ---------------------- fetch social profile ----------------------
  Future<void> fetchSocialProfile(String network, String usernameOrLink) async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      ProfileData profile;
      switch (network.toLowerCase()) {
        case 'instagram':
          profile = await networkService.getInstagramProfile(
            usernameOrLink: usernameOrLink,
          );
          break;
        default:
          profile = ProfileData(
            url: '',
            username: usernameOrLink,
            fullName: usernameOrLink,
            profilePicUrl: '',
            followers: 0,
            followees: 0,
            totalPosts: 0,
          );
      }
      addUserSocial(network, profile);
    } catch (e) {
      debugPrint('Error fetching $network: $e');
    } finally {
      emit(state.copyWith(status: RegisterStatus.initial));
    }
  }

  Future<void> startSocialAuth(BuildContext context, String network) async {
    switch (network.toLowerCase()) {
      case 'instagram':
        final assetPath = 'assets/icons/social_networks/Instagram.png';
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SocialDetailScreen(label: network, assetPath: assetPath),
          ),
        );
        if (result != null && result is String) {
          await fetchSocialProfile(network, result);
        }
        break;

      case 'youtube':
        final assetPath = 'assets/icons/social_networks/Youtube.png';
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SocialDetailScreen(label: network, assetPath: assetPath),
          ),
        );
        if (result != null && result is String) {
          debugPrint('✅ Simulación de fetch YouTube con input: $result');
          // Aquí podrías llamar a fetchSocialProfile('youtube', result) después
        }
        break;

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
