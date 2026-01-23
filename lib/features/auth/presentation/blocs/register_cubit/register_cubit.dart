import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/add_network_service_direct.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_network_service_click.dart';
import 'package:migozz_app/features/auth/services/add_networks/add_network_service_user.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/auth/services/pre_register_service.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final LocationService _locationService;
  final AddNetworkServiceClick _clickService = AddNetworkServiceClick();
  final AddNetworkServiceUser _userService = AddNetworkServiceUser();
  final AddNetworkServiceDirect _directService = AddNetworkServiceDirect();
  final PreRegisterService _preRegisterService = PreRegisterService();

  // ✅ Callback para sincronización con EditCubit
  Function(List<Map<String, dynamic>>)? onSocialEcosystemUpdated;

  File? avatarFile;
  File? voiceNoteFile;

  RegisterCubit(this._locationService) : super(const RegisterState());

  // ==================== PRE-REGISTRO ====================
  /// Check if email is pre-registered and set the username if found
  Future<bool> checkPreRegister(String email) async {
    debugPrint('🔍 [RegisterCubit] Checking pre-register for: $email');

    final preRegisterData = await _preRegisterService.getPreRegisterByEmail(
      email,
    );

    if (preRegisterData.isPreRegistered) {
      debugPrint('✅ [RegisterCubit] User is pre-registered!');
      debugPrint('   - Username: ${preRegisterData.username}');
      debugPrint('   - PreOrderId: ${preRegisterData.preOrderId}');

      emit(
        state.copyWith(
          isPreRegistered: true,
          preOrderId: preRegisterData.preOrderId,
          username: preRegisterData.username,
          email: email,
        ),
      );

      return true;
    }

    debugPrint('ℹ️ [RegisterCubit] User is NOT pre-registered');
    emit(
      state.copyWith(isPreRegistered: false, preOrderId: null, email: email),
    );

    return false;
  }

  /// Marca al usuario como pre-registrado (usado cuando viene de Google/Apple con pre-order)
  /// Esto sincroniza el estado del RegisterCubit con el documento de Firestore
  void markAsPreRegistered({String? username, String? email}) {
    debugPrint('✅ [RegisterCubit] Marcando como pre-registrado');
    debugPrint('   - Username reservado: $username');
    debugPrint('   - Email: $email');

    emit(
      state.copyWith(isPreRegistered: true, username: username, email: email),
    );
  }

  /// Delete pre-order document after successful registration
  Future<bool> deletePreOrder() async {
    final preOrderId = state.preOrderId;
    if (preOrderId == null || !state.isPreRegistered) {
      debugPrint('ℹ️ [RegisterCubit] No pre-order to delete');
      return true; // Nothing to delete
    }

    debugPrint('🗑️ [RegisterCubit] Deleting pre-order: $preOrderId');
    final success = await _preRegisterService.deletePreOrder(preOrderId);

    if (success) {
      debugPrint('✅ [RegisterCubit] Pre-order deleted successfully');
      emit(state.copyWith(isPreRegistered: false, preOrderId: null));
    } else {
      debugPrint('⚠️ [RegisterCubit] Failed to delete pre-order');
    }

    return success;
  }

  /// Migrate pre-order document to new Firebase Auth UID
  /// This should be called instead of deletePreOrder for pre-registered users
  Future<bool> migratePreOrder({
    required String newUid,
    Map<String, dynamic>? userData,
  }) async {
    final preOrderId = state.preOrderId;
    final isPreReg = state.isPreRegistered;

    debugPrint('🔍 [RegisterCubit] migratePreOrder called');
    debugPrint('   - preOrderId: $preOrderId');
    debugPrint('   - isPreRegistered: $isPreReg');
    debugPrint('   - newUid: $newUid');

    if (preOrderId == null || !isPreReg) {
      debugPrint(
        '⚠️ [RegisterCubit] No pre-order to migrate (preOrderId=$preOrderId, isPreReg=$isPreReg)',
      );
      return false; // Return false to indicate no migration happened
    }

    debugPrint('🔄 [RegisterCubit] Migrating pre-order: $preOrderId → $newUid');
    final success = await _preRegisterService.migratePreOrder(
      preOrderId: preOrderId,
      newUid: newUid,
      userData: userData,
    );

    if (success) {
      debugPrint('✅ [RegisterCubit] Pre-order migrated successfully');
      emit(state.copyWith(isPreRegistered: false, preOrderId: null));
    } else {
      debugPrint('⚠️ [RegisterCubit] Failed to migrate pre-order');
    }

    return success;
  }

  // ==================== RESPUESTA IA ====================
  void setAiResponse(bool value) {
    emit(state.copyWith(loadigAiResponse: value));
  }

  // ==================== UBICACIÓN ====================
  Future<void> fetchLocation(String lang) async {
    final location = await _locationService.initAndFetchAddress(lang: lang);
    if (location != null && location.hasCityAndCountry) {
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
  void setSocialEcosystem(List<Map<String, dynamic>> platforms) => emit(
    state.copyWith(
      socialEcosystem: platforms,
      regProgress: RegisterStatusProgress.location,
    ),
  );

  /// Para edición - NO cambia el regProgress
  void updateSocialEcosystemOnly(List<Map<String, dynamic>> platforms) {
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
          content: Text(
            '${config.displayName}${'register.validations.socialNotAvailable'.tr()}',
          ),
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
            // Variable local para rastrear cancelación
            bool userCancelled = false;

            // Show custom loading dialog with cancel button
            showProfileLoader(
              context,
              platform: config.displayName,
              onCancel: () {
                debugPrint('❌ User cancelled connection');
                userCancelled = true;
              },
            );

            try {
              await _handleManualAuth(context, network, value, inEditMode);

              // Check if user cancelled
              if (!userCancelled && context.mounted) {
                Navigator.of(context).pop(); // Close loader
                Navigator.of(context).pop(); // Close bottom sheet

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'addSocials.messages.socialConnected'.tr(
                        namedArgs: {'platform': config.displayName},
                      ),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ Error en manual auth: $e');

              if (context.mounted) {
                Navigator.of(context).pop(); // Close loader

                if (!userCancelled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
          content: Text(
            '${'register.validations.socialErrorConnected'.tr()}$network',
          ),
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
      Map<String, dynamic> rawData;

      // ✅ Verificar si es una red "directa" (no requiere scraping)
      final isDirectNetwork = _isDirectNetwork(network);

      if (isDirectNetwork) {
        // Usar servicio directo (sin scraping)
        rawData = await _directService.createDirectProfile(
          network: network,
          input: usernameOrLink,
        );
      } else {
        // Usar servicio de scraping normal
        rawData = await _userService.getProfileByUsernameOrLink(
          network: network,
          usernameOrLink: usernameOrLink,
        );
      }

      // Normalizar según la red
      final profileData = _normalizeProfile(network, rawData);

      debugPrint('📊 [$network] Data normalized:');
      debugPrint('   Data: $profileData');

      // Actualizar el ecosistema social
      final current = List<Map<String, dynamic>>.from(
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

  bool _isDirectNetwork(String network) {
    const directNetworks = [
      'website',
      'shopify',
      'woocommerce',
      'etsy',
      'whatsapp',
      'telegram',
    ];
    return directNetworks.contains(network.toLowerCase());
  }

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
      case 'twitch':
        return normalizeTwitch(rawData);
      case 'kick':
        return normalizeKick(rawData);
      case 'trovo':
        return normalizeTrovo(rawData);

      // 🆕 NUEVOS NORMALIZADORES
      case 'pinterest':
        return normalizePinterest(rawData);
      case 'reddit':
        return normalizeReddit(rawData);
      case 'threads':
        return normalizeThreads(rawData);
      case 'soundcloud':
        return normalizeSoundCloud(rawData);
      case 'discord':
        return normalizeDiscord(rawData);
      case 'snapchat':
        return normalizeSnapchat(rawData);

      default:
        // Normalización genérica
        return {
          'username': rawData['username'] ?? rawData['name'] ?? '',
          'followers': rawData['followers'] ?? rawData['follower_count'] ?? 0,
          'url': rawData['url'] ?? rawData['profile_url'] ?? '',
          'profile_image_url': rawData['profile_image_url'] ?? '',
        };
    }
  }

  /// Public method to add a network profile by username/link.
  /// Returns the normalized profile data, or null if validation fails.
  Future<Map<String, dynamic>?> addNetworkByUsername({
    required String network,
    required String usernameOrLink,
    required String iconPath,
  }) async {
    try {
      Map<String, dynamic> rawData;

      final isDirectNetwork = _isDirectNetwork(network);

      if (isDirectNetwork) {
        rawData = await _directService.createDirectProfile(
          network: network,
          input: usernameOrLink,
        );
      } else {
        rawData = await _userService.getProfileByUsernameOrLink(
          network: network,
          usernameOrLink: usernameOrLink,
        );
      }

      final profileData = _normalizeProfile(network, rawData);

      // Add iconPath to the profile
      profileData['iconPath'] = iconPath;

      debugPrint('📊 [$network] Profile validated and normalized');
      return profileData;
    } catch (e) {
      debugPrint('❌ Error validating $network profile: $e');
      return null;
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
          // state.gender != null &&
          hasLocationData &&
          state.phone != null; // &&
      // state.category != null &&
      // state.interests != null;

      final completeForGoogle =
          state.language != null &&
          // state.gender != null &&
          hasLocationData &&
          state.phone != null; // &&
      // state.category != null &&
      // state.interests != null;

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
