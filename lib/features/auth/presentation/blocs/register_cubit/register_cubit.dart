// ignore_for_file: use_build_context_synchronously

import 'dart:io'; // 👈 No olvides este import para File
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_networks.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
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
      emit(state.copyWith(location: location));
    }
  }

  void updateLocation(LocationDTO? location) {
    emit(state.copyWith(location: location));
  }

  // ---------------------- Otros setters (sin cambios relevantes) ----------------------
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
        state.copyWith(fullName: fullName, regProgress: RegisterStatusProgress.username),
      );

  void setUsername(String username) => emit(
        state.copyWith(username: username, regProgress: RegisterStatusProgress.gender),
      );

  void setGender(String gender) => emit(
        state.copyWith(gender: gender, regProgress: RegisterStatusProgress.socialEcosystem),
      );

  void setSocialEcosystem(List<Map<String, Map<String, dynamic>>> platforms) =>
      emit(
        state.copyWith(
          socialEcosystem: platforms,
          regProgress: RegisterStatusProgress.location,
        ),
      );

  void setSocialEcosystemEmty() =>
      emit(state.copyWith(regProgress: RegisterStatusProgress.location));

  void setLocation(LocationDTO location) =>
      emit(state.copyWith(location: location));

  void setVerifyLocation() => emit(
        state.copyWith(regProgress: RegisterStatusProgress.emailVerification),
      );

  void updateEmailVerification(EmailVerification status) => emit(
        state.copyWith(
          emailVerification: status,
          regProgress: RegisterStatusProgress.avatarUrl,
        ),
      );

  // picture profile helpers (no cambian el flujo de registro)
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

  // ---------------------- checkCompletion (sin dependencias de media) ----------------------
  Future<void> checkCompletion({
    bool forGoogle = false,
    String? uid,
  }) async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
    try {
      // NOTA: Ya no requerimos ni subimos archivos para completar el registro.
      // Solo validamos los campos obligatorios del flujo.
      final completeFull = state.email != null &&
          state.language != null &&
          state.fullName != null &&
          state.username != null &&
          state.gender != null &&
          state.location != null &&
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      final completeForGoogle = state.language != null &&
          state.gender != null &&
          state.location != null &&
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      final complete = forGoogle ? completeForGoogle : completeFull;

      debugPrint('✅ [Cubit] Registro completo (forGoogle=$forGoogle): $complete');

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
    // mismo comportamiento que antes (sin cambios)
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

                  final current = List<Map<String, Map<String, dynamic>>>.from(
                    state.socialEcosystem ?? [],
                  );

                  current.add({network.toLowerCase(): profileData});
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
