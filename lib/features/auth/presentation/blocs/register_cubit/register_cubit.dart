// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_networks.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final LocationService _locationService;
  final AddNetworkService networkService = AddNetworkService();

  File? avatarFile;
  File? voiceNoteFile;

  RegisterCubit(this._locationService) : super(const RegisterState()) {
    fetchLocation();
  }

  // respuesta de la ia
  void setAiResponse(bool value) {
    emit(state.copyWith(loadigAiResponse: value));
  }

  // Método para obtener ubicación
  Future<void> fetchLocation() async {
    final location = await _locationService.initAndFetchAddress();
    if (location != null) {
      debugPrint(
        '📍 [Cubit] Ubicación detectada: ${location.city}, ${location.state}, ${location.country}',
      );
      emit(state.copyWith(location: location));
    } else {
      debugPrint('📍 [Cubit] No se pudo detectar ubicación');
      // Establecer una ubicación vacía para que se pregunte manualmente
      emit(state.copyWith(location: LocationDTO.empty()));
    }
  }

  void updateLocation(LocationDTO? location) {
    emit(state.copyWith(location: location));
  }

  // ---------------------- MÉTODOS DE UBICACIÓN ----------------------

  // Método para cuando el usuario confirma la ubicación detectada (dice "Sí")
  void confirmLocation() {
    debugPrint('📍 [Cubit] Usuario confirmó la ubicación');
    emit(state.copyWith(regProgress: RegisterStatusProgress.emailVerification));
  }

  // Método para cuando el usuario rechaza usar ubicación (dice "No")
  void rejectLocation() {
    debugPrint('📍 [Cubit] Usuario rechazó usar ubicación');
    emit(
      state.copyWith(
        location: LocationDTO.empty(), // 👈 Ubicación vacía pero no null
        regProgress: RegisterStatusProgress.emailVerification,
      ),
    );
  }

  // Método para cuando la ubicación es incorrecta (pedir nueva ubicación)
  void requestCorrectLocation() {
    debugPrint(
      '📍 [Cubit] Usuario reportó ubicación incorrecta, solicitando nueva',
    );
    // Resetear para permitir nueva detección o ingreso manual
    emit(
      state.copyWith(
        location: null, // Permitir que se vuelva a pedir
        regProgress: RegisterStatusProgress.location,
      ),
    );
  }

  // ---------------------- Otros setters ----------------------
  void updateEmail(String email) => emit(state.copyWith(email: email));

  void setEmail(String email) => emit(
    state.copyWith(email: email, regProgress: RegisterStatusProgress.language),
  );

  void setLanguage(String language) => emit(
    state.copyWith(
      language: language,
      regProgress: RegisterStatusProgress.fullName,
    ),
  );

  void setFullName(String fullName) => emit(
    state.copyWith(
      fullName: fullName,
      regProgress: RegisterStatusProgress.username,
    ),
  );

  void setUsername(String username) => emit(
    state.copyWith(
      username: username,
      regProgress: RegisterStatusProgress.gender,
    ),
  );

  void setGender(String gender) => emit(
    state.copyWith(
      gender: gender,
      regProgress: RegisterStatusProgress.socialEcosystem,
    ),
  );

  // 🔹 MÉTODO ORIGINAL: Para registro - CAMBIA el regProgress
  void setSocialEcosystem(List<Map<String, Map<String, dynamic>>> platforms) =>
      emit(
        state.copyWith(
          socialEcosystem: platforms,
          regProgress: RegisterStatusProgress.location,
        ),
      );

  // 🔹 NUEVO MÉTODO: Para edición - NO cambia el regProgress
  void updateSocialEcosystemOnly(
    List<Map<String, Map<String, dynamic>>> platforms,
  ) {
    debugPrint(
      '🔧 [RegisterCubit] Actualizando socialEcosystem SIN cambiar regProgress',
    );
    emit(state.copyWith(socialEcosystem: platforms));
  }

  void setSocialEcosystemEmty() =>
      emit(state.copyWith(regProgress: RegisterStatusProgress.location));

  void setLocation(LocationDTO location) =>
      emit(state.copyWith(location: location));

  // 👇 Mantener este método por compatibilidad, pero ahora usa confirmLocation
  void setVerifyLocation() => confirmLocation();

  void updateEmailVerification(EmailVerification status) => emit(
    state.copyWith(
      emailVerification: status,
      regProgress: RegisterStatusProgress.avatarUrl,
    ),
  );

  // picture profile helpers
  void setAvatarFile(File file) => avatarFile = file;

  void setAvatarUrl(String avatarUrl) => emit(
    state.copyWith(
      avatarUrl: avatarUrl,
      regProgress: RegisterStatusProgress.phone,
    ),
  );

  void clearAvatarUrl() => emit(state.copyWith(avatarUrl: null));

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

  /// 🔹 Método inteligente para subir archivos
  Future<Map<MediaType, String>> uploadUserMedia({
    required Map<MediaType, File> files,
    String? firebaseUid,
  }) async {
    final mediaService = UserMediaService();

    // Si hay UID (Google), usar directamente
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      debugPrint('📤 [Cubit] Google user - uploading with UID: $firebaseUid');
      return await mediaService.uploadFiles(uid: firebaseUid, files: files);
    }

    // Registro normal - usar email temporal
    final email = state.email;
    if (email == null || email.isEmpty) {
      throw Exception('Email no disponible');
    }

    debugPrint('📤 [Cubit] Normal registration - uploading with email: $email');
    return await mediaService.uploadFilesTemporarily(
      email: email,
      files: files,
    );
  }

  // category
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
  Future<void> checkCompletion({bool forGoogle = false, String? uid}) async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
    try {
      // La ubicación debe existir (no null), pero puede estar vacía
      final hasLocationData = state.location != null;

      final completeFull =
          state.email != null &&
          state.language != null &&
          state.fullName != null &&
          state.username != null &&
          state.gender != null &&
          hasLocationData && // 👈 Solo verificamos que exista el objeto
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      final completeForGoogle =
          state.language != null &&
          state.gender != null &&
          hasLocationData && // 👈 Lo mismo aquí
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      final complete = forGoogle ? completeForGoogle : completeFull;

      debugPrint(
        '✅ [Cubit] Registro completo (forGoogle=$forGoogle): $complete',
      );
      debugPrint('📍 [Cubit] Location exists: $hasLocationData');
      debugPrint('📍 [Cubit] Location isEmpty: ${state.location?.isEmpty}');
      if (state.location != null) {
        debugPrint(
          '📍 [Cubit] Location data: ${state.location!.city}, ${state.location!.state}, ${state.location!.country}',
        );
      }

      if (state.isComplete != complete) {
        emit(state.copyWith(isComplete: complete));
      } else {
        emit(state.copyWith(status: RegisterIsLogin.initial));
      }
    } catch (e) {
      debugPrint('❌ [Cubit] Error en checkCompletion: $e');
      emit(state.copyWith(status: RegisterIsLogin.initial));
    }
  }

  // resto del cubit sin cambios
  Future<void> fetchSocialProfile(String network, String usernameOrLink) async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
    try {
      switch (network.toLowerCase()) {
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

  // 🔹 NUEVO PARÁMETRO: inEditMode para saber si estamos editando
  Future<void> startSocialAuth(
    BuildContext context,
    String network,
    String assetPath, {
    bool inEditMode = false, // 👈 NUEVO
  }) async {
    switch (network.toLowerCase()) {
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
                  Map<String, dynamic> profileData = {};

                  if (network.toLowerCase() == 'youtube') {
                    final rawData = await networkService.getYouTubeProfile(
                      handleOrUrl: value,
                    );
                    profileData = normalizeYouTube(rawData);

                    debugPrint('📊 [RegisterCubit] YouTube data normalized:');
                    debugPrint('   Username: ${profileData['username']}');
                    debugPrint('   Followers: ${profileData['followers']}');
                    debugPrint('   URL: ${profileData['url']}');
                  }

                  final current = List<Map<String, Map<String, dynamic>>>.from(
                    state.socialEcosystem ?? [],
                  );

                  current.add({network.toLowerCase(): profileData});

                  // 🔹 Usar el método correcto según el modo
                  if (inEditMode) {
                    updateSocialEcosystemOnly(current);
                  } else {
                    setSocialEcosystem(current);
                  }
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

      case 'instagram':
        await networkService.startInstagramAuth(context);
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
      case 'facebook':
        await networkService.startFacebookAuth(context);
        break;
      default:
        debugPrint('Red social no soportada: $network');
    }
  }

  void reset() {
    emit(RegisterState.initial());
  }
}
