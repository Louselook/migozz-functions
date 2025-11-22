// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_network_service_click.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_network_service_user.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final LocationService _locationService;
  final AddNetworkServiceClick _clickService = AddNetworkServiceClick();
  final AddNetworkServiceUser _userService = AddNetworkServiceUser();

  // ✅ Callback para sincronización con EditCubit
  Function(List<Map<String, Map<String, dynamic>>>)? onSocialEcosystemUpdated;

  File? avatarFile;
  File? voiceNoteFile;

  RegisterCubit(this._locationService) : super(const RegisterState()) {
    fetchLocation();
  }

  // ==================== RESPUESTA IA ====================
  void setAiResponse(bool value) {
    emit(state.copyWith(loadigAiResponse: value));
  }

  // ==================== UBICACIÓN ====================
  Future<void> fetchLocation() async {
    final location = await _locationService.initAndFetchAddress();
    if (location != null) {
      debugPrint(
        '📍 [Cubit] Ubicación detectada: ${location.city}, ${location.state}, ${location.country}',
      );
      emit(state.copyWith(location: location));
    } else {
      debugPrint('📍 [Cubit] No se pudo detectar ubicación');
      emit(state.copyWith(location: LocationDTO.empty()));
    }
  }

  void updateLocation(LocationDTO? location) {
    emit(state.copyWith(location: location));
  }

  void confirmLocation() {
    debugPrint('📍 [Cubit] Usuario confirmó la ubicación');
    emit(state.copyWith(regProgress: RegisterStatusProgress.emailVerification));
  }

  void rejectLocation() {
    debugPrint('📍 [Cubit] Usuario rechazó usar ubicación');
    emit(
      state.copyWith(
        location: LocationDTO.empty(),
        regProgress: RegisterStatusProgress.emailVerification,
      ),
    );
  }

  void requestCorrectLocation() {
    debugPrint(
      '📍 [Cubit] Usuario reportó ubicación incorrecta, solicitando nueva',
    );
    emit(
      state.copyWith(
        location: null,
        regProgress: RegisterStatusProgress.location,
      ),
    );
  }

  void setLocation(LocationDTO location) =>
      emit(state.copyWith(location: location));

  void setVerifyLocation() => confirmLocation();

  // ==================== SETTERS DE REGISTRO ====================
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

  void setPhone(String phone) => emit(
    state.copyWith(
      phone: phone,
      regProgress: RegisterStatusProgress.voiceNoteUrl,
    ),
  );

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

  // ==================== SOCIAL ECOSYSTEM ====================

  /// Para registro - CAMBIA el regProgress
  void setSocialEcosystem(List<Map<String, Map<String, dynamic>>> platforms) =>
      emit(
        state.copyWith(
          socialEcosystem: platforms,
          regProgress: RegisterStatusProgress.location,
        ),
      );

  /// Para edición - NO cambia el regProgress
  void updateSocialEcosystemOnly(
    List<Map<String, Map<String, dynamic>>> platforms,
  ) {
    debugPrint(
      '🔧 [RegisterCubit] Actualizando socialEcosystem SIN cambiar regProgress',
    );
    emit(state.copyWith(socialEcosystem: platforms));

    // ✅ Notificar al callback si existe (para sincronizar con EditCubit)
    if (onSocialEcosystemUpdated != null) {
      debugPrint('🔄 [RegisterCubit] Sincronizando con EditCubit');
      onSocialEcosystemUpdated!(platforms);
    }
  }

  void setSocialEcosystemEmty() =>
      emit(state.copyWith(regProgress: RegisterStatusProgress.location));

  /// Inicia el flujo de vinculación de red social
  Future<void> startSocialAuth(
    BuildContext context,
    String network,
    String assetPath, {
    bool inEditMode = false,
  }) async {
    final config = SocialNetworks.getConfig(network);

    if (config == null) {
      debugPrint('❌ Red social no encontrada: $network');
      return;
    }

    if (!config.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${config.displayName} no está disponible aún'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNetworkBottomSheet(
        networkConfig: config,
        onOptionSelected: (mode, value) async {
          if (mode == NetworkAuthMode.click) {
            Navigator.of(context).pop();
            await _handleClickAuth(context, network, inEditMode);
          } else if (mode == NetworkAuthMode.manual && value != null) {
            LoadingOverlay.show(context);

            try {
              await _handleManualAuth(context, network, value, inEditMode);
              Navigator.of(context).pop();
            } catch (e) {
              debugPrint('❌ Error en manual auth: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            } finally {
              LoadingOverlay.hide(context);
            }
          }
        },
      ),
    );
  }

  /// Manejar autenticación por click (OAuth)
  Future<void> _handleClickAuth(
    BuildContext context,
    String network,
    bool inEditMode,
  ) async {
    try {
      await _clickService.startOAuthAuth(context: context, network: network);

      debugPrint('✅ OAuth iniciado para $network');
      // El deeplink manejará la sincronización automáticamente
    } catch (e) {
      debugPrint('❌ Error en OAuth: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to $network'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Manejar autenticación manual (username/link)
  Future<void> _handleManualAuth(
    BuildContext context,
    String network,
    String usernameOrLink,
    bool inEditMode,
  ) async {
    try {
      // Obtener datos del perfil
      final rawData = await _userService.getProfileByUsernameOrLink(
        network: network,
        usernameOrLink: usernameOrLink,
      );

      // Normalizar según la red
      final profileData = _normalizeProfile(network, rawData);

      debugPrint('📊 [$network] Data normalized:');
      debugPrint('   Username: ${profileData['username']}');
      debugPrint('   Followers: ${profileData['followers']}');
      debugPrint('   URL: ${profileData['url']}');

      // Actualizar el ecosistema social
      final current = List<Map<String, Map<String, dynamic>>>.from(
        state.socialEcosystem ?? [],
      );

      current.add({network.toLowerCase(): profileData});

      // Usar el método correcto según el modo
      if (inEditMode) {
        updateSocialEcosystemOnly(current);
      } else {
        setSocialEcosystem(current);
      }

      debugPrint('✅ $network agregada al ecosistema');
    } catch (e) {
      debugPrint('❌ Error obteniendo perfil de $network: $e');
      rethrow;
    }
  }

  /// Normalizar datos del perfil según la red social
  Map<String, dynamic> _normalizeProfile(
    String network,
    Map<String, dynamic> rawData,
  ) {
    switch (network.toLowerCase()) {
      case 'youtube':
        return normalizeYouTube(rawData);
      case 'instagram':
        return normalizeInstagram(rawData);
      case 'twitter':
        return normalizeTwitter(rawData);
      case 'tiktok':
        return normalizeTikTok(rawData);
      case 'spotify':
        return normalizeSpotify(rawData);
      case 'facebook':
        return normalizeFacebook(rawData);
      case 'linkedin':
        return normalizeLinkedIn(rawData);
      default:
        // Normalización genérica
        return {
          'username': rawData['username'] ?? rawData['name'] ?? '',
          'followers': rawData['followers'] ?? rawData['follower_count'] ?? 0,
          'url': rawData['url'] ?? rawData['profile_url'] ?? '',
        };
    }
  }

  // ==================== EMAIL VERIFICATION ====================
  void updateEmailVerification(EmailVerification status) => emit(
    state.copyWith(
      emailVerification: status,
      regProgress: RegisterStatusProgress.avatarUrl,
    ),
  );

  // ==================== AVATAR ====================
  void setAvatarFile(File file) => avatarFile = file;

  void setAvatarUrl(String avatarUrl) => emit(
    state.copyWith(
      avatarUrl: avatarUrl,
      regProgress: RegisterStatusProgress.phone,
    ),
  );

  void clearAvatarUrl() => emit(state.copyWith(avatarUrl: null));

  // ==================== VOICE NOTE ====================
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

  // ==================== MEDIA UPLOAD ====================
  Future<Map<MediaType, String>> uploadUserMedia({
    required Map<MediaType, File> files,
    String? firebaseUid,
  }) async {
    final mediaService = UserMediaService();

    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      debugPrint('📤 [Cubit] Google user - uploading with UID: $firebaseUid');
      return await mediaService.uploadFiles(uid: firebaseUid, files: files);
    }

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

  // ==================== CHECK COMPLETION ====================
  Future<void> checkCompletion({bool forGoogle = false, String? uid}) async {
    emit(state.copyWith(status: RegisterIsLogin.loading));
    try {
      final hasLocationData = state.location != null;

      final completeFull =
          state.email != null &&
          state.language != null &&
          state.fullName != null &&
          state.username != null &&
          state.gender != null &&
          hasLocationData &&
          state.phone != null &&
          state.category != null &&
          state.interests != null;

      final completeForGoogle =
          state.language != null &&
          state.gender != null &&
          hasLocationData &&
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

  // ==================== RESET ====================
  void reset() {
    emit(RegisterState.initial());
  }
}
