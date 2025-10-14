import 'dart:io'; // 👈 No olvides este import para File
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_networks.dart';
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

  // respuesta de la ia
  void setAiResponse(bool value) {
    emit(state.copyWith(loadigAiResponse: value));
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

  // ---------------------- Otros setters ----------------------
  // email
  void updateEmail(String email) => emit(state.copyWith(email: email));
  void setEmail(String email) => emit(
    state.copyWith(email: email, regProgress: RegisterStatusProgress.language),
  );
  // language
  void setLanguage(String language) => emit(
    state.copyWith(
      language: language,
      regProgress: RegisterStatusProgress.fullName,
    ),
  );
  // nombre
  void setFullName(String fullName) => emit(
    state.copyWith(
      fullName: fullName,
      regProgress: RegisterStatusProgress.username,
    ),
  );
  // username
  void setUsername(String username) => emit(
    state.copyWith(
      username: username,
      regProgress: RegisterStatusProgress.gender,
    ),
  );
  // gender
  void setGender(String gender) => emit(
    state.copyWith(
      gender: gender,
      regProgress: RegisterStatusProgress.socialEcosystem,
    ),
  );
  // social networks
  void setSocialEcosystem(List<Map<String, Map<String, dynamic>>> platforms) =>
      emit(
        state.copyWith(
          socialEcosystem: platforms,
          regProgress: RegisterStatusProgress.location,
        ),
      );
  void setSocialEcosystemEmty() =>
      emit(state.copyWith(regProgress: RegisterStatusProgress.location));

  Future<void> loadSocialsFromFirestore({String? uid}) async {
    try {
      // opcional: emitir estado de loading si tienes uno
      final platforms = await _authService.fetchUserSocialEcosystem(uid: uid);

      if (platforms.isEmpty) {
        // no hay redes asociadas
        setSocialEcosystemEmty();
      } else {
        setSocialEcosystem(platforms);
      }
    } catch (e, st) {
      debugPrint('🔥 Error cargando socials en cubit: $e\n$st');
      // fallback seguro
      setSocialEcosystemEmty();
    }
  }
  
  // location
  void setLocation(LocationDTO location) =>
      emit(state.copyWith(location: location));
  void setVerifyLocation() => emit(
    state.copyWith(regProgress: RegisterStatusProgress.emailVerification),
  );
  // email verification
  void updateEmailVerification(EmailVerification status) => emit(
    state.copyWith(
      emailVerification: status,
      regProgress: RegisterStatusProgress.avatarUrl,
    ),
  );
  // picture profile
  void setAvatarFile(File file) => avatarFile = file;
  void setAvatarUrl(String avatarUrl) => emit(
    state.copyWith(
      avatarUrl: avatarUrl,
      regProgress: RegisterStatusProgress.phone,
    ),
  );
  void clearAvatarUrl() => emit(state.copyWith(avatarUrl: null));

  // phone
  void setPhone(String phone) => emit(
    state.copyWith(
      phone: phone,
      regProgress: RegisterStatusProgress.voiceNoteUrl,
    ),
  );

  // voice audio
  void setVoiceNoteFile(File file) {
    voiceNoteFile = file;
    debugPrint('🎤 [Cubit] setVoiceNoteFile llamado');
    debugPrint('🎤 [Cubit] Archivo path: ${file.path}');
    debugPrint('🎤 [Cubit] Archivo existe: ${file.existsSync()}');
    debugPrint('🎤 [Cubit] voiceNoteFile guardado: ${voiceNoteFile?.path}');
  }

  void setVoiceNoteUrl(String voiceNoteUrl) {
    debugPrint('🎤 [Cubit] setVoiceNoteUrl llamado: $voiceNoteUrl');
    emit(
      state.copyWith(
        voiceNoteUrl: voiceNoteUrl,
        regProgress: RegisterStatusProgress.category,
      ),
    );
  }

  //category
  void setCategories(List<String>? category) => emit(
    state.copyWith(
      category: category,
      regProgress: RegisterStatusProgress.interests,
    ),
  );
  void setInterests(Map<String, List<String>> interests) =>
      emit(state.copyWith(interests: interests));

  void setCurrentOTP(String currentOTP) => emit(
    state.copyWith(
      currentOTP: currentOTP,
      regProgress: RegisterStatusProgress.doneChat,
    ),
  );

  // ---------------------- checkCompletion ----------------------
  Future<void> checkCompletion() async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
    try {
      final Map<MediaType, File> filesToUpload = {};

      if (avatarFile != null) {
        filesToUpload[MediaType.avatar] = avatarFile!;
        debugPrint('✅ [Cubit] Avatar agregado para subir: ${avatarFile!.path}');
      }

      if (voiceNoteFile != null) {
        filesToUpload[MediaType.voice] = voiceNoteFile!;
        debugPrint('✅ [Cubit] Audio agregado para subir: ${voiceNoteFile!.path}');
      }

      // Subir temporalmente con email
      if (filesToUpload.isNotEmpty) {
        try {
          final mediaUrls = await _mediaService.uploadFilesTemporarily(
            email: state.email!,
            files: filesToUpload,
          );

          if (mediaUrls.containsKey(MediaType.avatar)) {
            setAvatarUrl(mediaUrls[MediaType.avatar]!);
          }
          if (mediaUrls.containsKey(MediaType.voice)) {
            setVoiceNoteUrl(mediaUrls[MediaType.voice]!);
          }
        } catch (e) {
          debugPrint('❌ [Cubit] Error subiendo archivos: $e');
        }
      }

      // Validar completitud
      final complete =
          state.email != null &&
          state.language != null &&
          state.fullName != null &&
          state.username != null &&
          state.gender != null &&
          state.location != null &&
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      debugPrint('✅ [Cubit] Registro completo: $complete');

      if (state.isComplete != complete) {
        emit(state.copyWith(isComplete: complete));
        await completeRegistration();
      } else {
        emit(state.copyWith(status: RegisterIsLogin.initial));
      }
    } catch (e) {
      debugPrint('❌ [Cubit] Error en checkCompletion: $e');
      emit(state.copyWith(status: RegisterIsLogin.initial));
    }
  }

// ---------------------- completeRegistration ----------------------
Future<String?> completeRegistration() async {
  try {
    if (!state.isComplete) {
      throw Exception('Faltan datos para completar el registro');
    }

    final userDTO = state.buildUserDTO();

    // Crear usuario en Firebase
    final userCredential = await _authService.signUpRegister(
      email: state.email!,
      otp: state.currentOTP!,
      userData: userDTO,
    );

    final uid = userCredential.user!.uid;

    // Asociar media (email → UID)
    await _mediaService.associateMediaToUid(
      uid: uid,
      email: state.email!,
    );

    return uid;
  } catch (e) {
    throw Exception('Error al registrar usuario: $e');
  } finally {
    emit(state.copyWith(status: RegisterIsLogin.success));
  }
}

  // ---------------------- fetch social profile ----------------------
  Future<void> fetchSocialProfile(String network, String usernameOrLink) async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
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
      emit(state.copyWith(status: RegisterIsLogin.initial));
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

                  // 4️⃣ Actualizar el cubit
                  setSocialEcosystem(current);
                } catch (e) {
                  debugPrint("❌ Error fetching $network profile: $e");
                } finally {
                  // ignore: use_build_context_synchronously
                  LoadingOverlay.hide(context);
                }

                // ignore: use_build_context_synchronously
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
      case 'facebook':
        await networkService.startFacebookAuth(context);
        break;
      default:
        debugPrint('Red social no soportada: $network');
    }
  }
}
