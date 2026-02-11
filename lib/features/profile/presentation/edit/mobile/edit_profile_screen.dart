import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_field.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_option_button.dart';
// import 'package:migozz_app/features/profile/presentation/edit/modules/edit_audio.dart';
// import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';

class EditProfileScreen extends StatefulWidget {
  final TutorialKeys tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;

  const EditProfileScreen({
    super.key,
    required this.tutorialKeys,
    this.profileTutorialKeys,
  });

  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthCtrl = TextEditingController();
  DateTime? _dob;
  String? _selectedGender;
  UserDTO? _initialUser;

  bool get hasUnsavedChanges => _hasUnsavedChanges();

  bool _hasUnsavedChanges() {
    if (_initialUser == null) return false;

    // Check Name
    if (nameCtrl.text.trim() != _initialUser!.displayName) return true;

    // Check Username
    if (usernameCtrl.text.trim() != _initialUser!.username) return true;

    // Check Phone
    if (phoneCtrl.text.trim() != (_initialUser!.phone ?? '')) return true;

    // Check Gender
    final initialGender = _normalizeGender(_initialUser!.gender);
    if (_selectedGender != initialGender) return true;

    // Check BirthDate
    // _dob is DateTime?, _initialUser.birthDate is DateTime?
    // Compare milliseconds or direct equality if exact same object, but safer by value.
    if (_dob != _initialUser!.birthDate) {
      if (_dob == null || _initialUser!.birthDate == null) return true;
      // Compare dates (ignore time if any, but usually start of day)
      // Assuming birthDate is just date.
      if (!DateUtils.isSameDay(_dob, _initialUser!.birthDate)) return true;
    }

    return false;
  }

  /// Muestra el diálogo de confirmación para repetir el tutorial
  Future<void> _showHelpDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'tutorial.help.confirmTitle'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'tutorial.help.confirmMessage'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'tutorial.help.cancelButton'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'tutorial.help.confirmButton'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Pedir replay y navegar al perfil principal.
      // El tutorial se ejecuta en Profile cuando la UI ya está montada.
      ProfileTutorialReplayBus.requestReplay();
      context.go('/profile');
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    genderCtrl.dispose();
    birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2010, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        birthCtrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _resetFields() {
    if (_initialUser == null) return;
    final user = _initialUser!;
    nameCtrl.text = user.displayName;
    usernameCtrl.text = user.username;
    // emailCtrl doesn't change
    phoneCtrl.text = user.phone ?? '';
    _selectedGender = _normalizeGender(user.gender);
    genderCtrl.text = _selectedGender ?? (user.gender ?? '');
    _dob = user.birthDate;
    if (user.birthDate != null) {
      birthCtrl.text =
          "${user.birthDate!.year}-${user.birthDate!.month.toString().padLeft(2, '0')}-${user.birthDate!.day.toString().padLeft(2, '0')}";
    } else {
      birthCtrl.text = '';
    }
  }

  Future<bool> confirmDiscardOrSave() async {
    if (!_hasUnsavedChanges()) return true;

    if (!mounted) return true;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'edit.unsavedChanges.title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'edit.unsavedChanges.message'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text(
              'edit.unsavedChanges.discard'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: Text(
              'edit.unsavedChanges.save'.tr(),
              style: const TextStyle(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );

    if (action == 'discard') {
      _resetFields();
      return true;
    } else if (action == 'save') {
      // ignore: use_build_context_synchronously
      final userId = context.read<AuthCubit>().state.firebaseUser?.uid;
      if (userId != null) {
        return await _saveProfile(userId);
      }
    }
    return false;
  }

  Future<bool> _saveProfile(String userId) async {
    final editCubit = context.read<EditCubit>();
    try {
      final newUsername = usernameCtrl.text.trim().toLowerCase();
      final currentUsername = _initialUser?.username.toLowerCase() ?? '';

      // Verificar si el username cambió y si ya está en uso
      if (newUsername != currentUsername && newUsername.isNotEmpty) {
        final userService = UserService(UserMediaService());
        final isTaken = await userService.isUsernameTaken(
          newUsername,
          excludeUserId: userId,
        );

        if (isTaken) {
          if (mounted) {
            await AlertGeneral.show(
              context,
              4,
              message: 'edit.validations.usernameTaken'.tr(),
              autoDismissAfter: const Duration(seconds: 3),
            );
          }
          return false;
        }
      }

      final data = {
        'displayName': nameCtrl.text.trim(),
        'username': newUsername,
        'phone': phoneCtrl.text.trim(),
        'gender': genderCtrl.text.trim(),
        'birthDate': _dob != null ? Timestamp.fromDate(_dob!) : null,
      };

      await editCubit.saveUserProfileField(userId: userId, updatedFields: data);

      // Update _initialUser with the new saved values to prevent false "unsaved changes" detection
      if (_initialUser != null) {
        _initialUser = _initialUser!.copyWith(
          displayName: nameCtrl.text.trim(),
          username: newUsername,
          phone: phoneCtrl.text.trim(),
          gender: genderCtrl.text.trim(),
          birthDate: _dob,
        );
      }

      if (mounted) {
        await AlertGeneral.show(
          context,
          1,
          message: "edit.validations.updateProfile".tr(),
          autoDismissAfter: const Duration(seconds: 1),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        await AlertGeneral.show(
          context,
          4,
          message: '${"edit.validations.errorUpdateProfile".tr()} $e',
        );
      }
      return false;
    }
  }

  Future<void> _confirmAndChangeLocation(String email) async {
    final svc = LocationService();

    if (mounted) {
      AlertGeneral.show(
        context,
        2,
        message: "edit.validations.detectLocation".tr(),
      );
    }

    final newLocation = await svc.initAndFetchAddress(
      lang: context.locale.languageCode == 'es' ? 'es' : 'en',
    );

    if (newLocation == null) {
      if (!mounted) return;
      AlertGeneral.show(
        context,
        4,
        message: "edit.validations.errorDetecLocation".tr(),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('buttons.confirm'.tr()),
        content: Text(
          "${"edit.editLocation.text1".tr()}"
          "${"edit.editLocation.text2".tr(namedArgs: {'city': newLocation.city, 'state': newLocation.state})}"
          "${"edit.editLocation.text3".tr(namedArgs: {'country': newLocation.country})}"
          "${"edit.editLocation.text4".tr()}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('buttons.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('buttons.confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      try {
        final editCubit = context.read<EditCubit>();
        final userId = context.read<AuthCubit>().state.firebaseUser?.uid;

        if (userId == null) {
          AlertGeneral.show(
            context,
            4,
            message: 'edit.validations.errorUserLogin'.tr(),
          );
          return;
        }

        final locationData = {'location': newLocation.toMap()};

        debugPrint('💾 [EditProfile] Guardando ubicación en Firestore...');
        debugPrint('   • UserId: $userId');
        debugPrint('   • Data: $locationData');

        await editCubit.saveUserProfileField(
          userId: userId,
          updatedFields: locationData,
        );

        if (!mounted) return;

        debugPrint('✅ [EditProfile] Ubicación guardada exitosamente');

        AlertGeneral.show(
          context,
          1,
          message: 'edit.validations.updateLocation'.tr(
            namedArgs: {
              'city': newLocation.city,
              'country': newLocation.country,
            },
          ),
        );
      } catch (e) {
        if (!mounted) return;

        debugPrint('❌ [EditProfile] Error guardando ubicación: $e');

        AlertGeneral.show(
          context,
          4,
          message: "edit.validations.errorUpdateLocation".tr(
            namedArgs: {'error': e.toString()},
          ),
        );
      }
    } else {
      debugPrint('🚫 [EditProfile] Usuario canceló el cambio de ubicación');
    }
  }

  String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    switch (value) {
      case 'male':
      case 'masculino':
      case 'm':
        return 'male';
      case 'female':
      case 'famale':
      case 'femenino':
      case 'f':
        return 'female';
      // case 'other':
      // case 'otro':
      //   return 'other';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canLeave = await confirmDiscardOrSave();
        if (canLeave && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            // Si no hay más páginas atrás, vuelve a home
            if (context.mounted) {
              context.go('/profile');
            }
          }
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          title: Text(
            'edit.presentation.title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back, color: Colors.white),
          //   onPressed: () => context.pop(),
          // ),
          actions: [
            // Botón de ayuda para repetir el tutorial
            if (widget.profileTutorialKeys != null)
              GestureDetector(
                onTap: _showHelpDialog,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _EditProfileBackground(),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final isTablet = width > 600;
                final horizontalPadding = isTablet ? width * 0.2 : width * 0.08;
                final topPadding =
                    MediaQuery.of(context).padding.top +
                    (kToolbarHeight * 0.35);

                return BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state.isLoadingProfile) {
                      return Center(
                        child: LoaderDialog(type: LoaderType.profileUpdate),
                      );
                    }
                    final user = state.userProfile;
                    if (user == null) {
                      return Center(
                        child: Text(
                          'edit.presentation.errorUserEmpty'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
                    } else {}

                    if (nameCtrl.text.isEmpty) {
                      _initialUser = user;
                      nameCtrl.text = user.displayName;
                      usernameCtrl.text = user.username;
                      emailCtrl.text = user.email;
                      phoneCtrl.text = user.phone ?? '';
                      _selectedGender = _normalizeGender(user.gender);
                      genderCtrl.text = _selectedGender ?? (user.gender ?? '');

                      if (user.birthDate != null) {
                        _dob = user.birthDate;
                        birthCtrl.text =
                            "${user.birthDate!.year}-${user.birthDate!.month.toString().padLeft(2, '0')}-${user.birthDate!.day.toString().padLeft(2, '0')}";
                      }
                    }

                    String formattedLocation =
                        'edit.presentation.locationNotSet'.tr();

                    if (user.location.isEmpty) {
                      formattedLocation = 'edit.presentation.locationNotSet'
                          .tr();
                    } else {
                      final locationParts = <String>[];
                      if (user.location.city.isNotEmpty) {
                        locationParts.add(user.location.city);
                      }
                      if (user.location.state.isNotEmpty) {
                        locationParts.add(user.location.state);
                      }
                      if (user.location.country.isNotEmpty) {
                        locationParts.add(user.location.country);
                      }

                      if (locationParts.isNotEmpty) {
                        formattedLocation = locationParts.join(', ');
                      }
                    }

                    final genderOptions = <String, String>{
                      'male': 'edit.presentation.genderOptions.male'.tr(),
                      'female': 'edit.presentation.genderOptions.female'.tr(),
                      // 'other': 'edit.presentation.genderOptions.other'.tr(),
                    };

                    final cardDecoration = BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    );

                    final actionRadius = width * 0.02;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topPadding,
                        horizontalPadding,
                        height * 0.08,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderCard(
                            width: width,
                            displayName: user.displayName,
                            username: user.username,
                            email: user.email,
                            avatarUrl: user.avatarUrl,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: cardDecoration,
                            child: Column(
                              children: [
                                ProfileField(
                                  hint: 'edit.presentation.fields.fullName'
                                      .tr(),
                                  controller: nameCtrl,
                                  icon: Icons.account_box,
                                ),
                                ProfileField(
                                  hint: 'edit.presentation.fields.nickname'
                                      .tr(),
                                  controller: usernameCtrl,
                                  icon: Icons.alternate_email,
                                ),
                                ProfileField(
                                  hint: 'edit.presentation.fields.email'.tr(),
                                  controller: emailCtrl,
                                  icon: Icons.mail,
                                  readOnly: true,
                                  // trailingIcon: Icons.lock_outline,
                                ),
                                ProfileField(
                                  hint: 'edit.presentation.fields.cellPhone'
                                      .tr(),
                                  controller: phoneCtrl,
                                  icon: Icons.phone,
                                ),
                                ProfileField(
                                  hint: 'edit.presentation.fields.dateOfBirth'
                                      .tr(),
                                  controller: birthCtrl,
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: _pickBirthday,
                                  // trailingIcon: Icons.calendar_month,
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          height: 20,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedGender,
                                          isExpanded: true,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          iconEnabledColor: Colors.white
                                              .withValues(alpha: 0.8),
                                          iconDisabledColor: Colors.white
                                              .withValues(alpha: 0.6),
                                          dropdownColor: Colors.black
                                              .withValues(alpha: 0.92),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                            border: InputBorder.none,
                                            prefixIcon: Padding(
                                              padding: const EdgeInsets.all(
                                                6.0,
                                              ),
                                              child: Container(
                                                height: 45,
                                                width: 45,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white.withValues(
                                                        alpha: 0.15,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.05,
                                                      ),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.transgender,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            hintStyle: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                            hintText:
                                                'edit.presentation.fields.gender'
                                                    .tr(),
                                          ),
                                          hint: Text(
                                            'edit.presentation.fields.gender'
                                                .tr(),
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          selectedItemBuilder: (context) {
                                            return genderOptions.entries
                                                .map(
                                                  (entry) => Text(
                                                    entry.value,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                                .toList();
                                          },
                                          items: genderOptions.entries
                                              .map(
                                                (entry) =>
                                                    DropdownMenuItem<String>(
                                                      value: entry.key,
                                                      child: Text(
                                                        entry.value,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedGender = value;
                                              genderCtrl.text = value ?? '';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ProfileField(
                                  hint: formattedLocation,
                                  icon: Icons.public,
                                  readOnly: true,
                                  onTap: () =>
                                      _confirmAndChangeLocation(user.email),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          // ProfileOptionButton(
                          //   icon: Icons.share_outlined,
                          //   text: 'edit.presentation.socials'.tr(),
                          //   onTap: () {
                          //     final userId = state.firebaseUser?.uid;
                          //     if (userId == null) {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         SnackBar(
                          //           content: Text(
                          //             'edit.validations.errorUserLogin'.tr(),
                          //           ),
                          //           backgroundColor: Colors.red,
                          //         ),
                          //       );
                          //       return;
                          //     }

                          //     final editCubit = context.read<EditCubit>();

                          //     // ✅ CLAVE: Inicializar con datos actuales del AuthCubit
                          //     final currentSocials =
                          //         state.userProfile?.socialEcosystem ?? [];
                          //     debugPrint(
                          //       '📱 [EditProfile] Inicializando con ${currentSocials.length} redes',
                          //     );

                          //     editCubit.initializeFromUser(
                          //       socialEcosystem: currentSocials,
                          //       category: state.userProfile?.category,
                          //       interests: state.userProfile?.interests,
                          //     );

                          //     editCubit.setEditItem(EditItem.socialEcosystem);

                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (_) => BlocProvider.value(
                          //           value: editCubit,
                          //           child: MoreUserDetails(
                          //             pageIndicator: 0,
                          //             mode: MoreUserDetailsMode.edit,
                          //             userId: userId,
                          //           ),
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // ),
                          ProfileOptionButton(
                            icon: Icons.logout,
                            text: 'edit.presentation.logOut'.tr(),
                            color: Colors.white.withValues(alpha: 0.15),
                            onTap: () async {
                              final confirm = await AlertGeneral.showConfirm(
                                context,
                                title: 'edit.presentation.logOut'.tr(),
                                message: 'edit.presentation.logOutConfirmation'
                                    .tr(),
                              );
                              if (confirm && context.mounted) {
                                showProfileLoader(
                                  context,
                                  type: LoaderType.logout,
                                );
                                try {
                                  await context.read<AuthCubit>().logout();
                                } finally {
                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                  }
                                }
                              }
                            },
                          ),

                          SizedBox(height: height * 0.03),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(actionRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: GradientButton(
                              onPressed: _confirmDeleteAccount,
                              width: double.infinity,
                              height: height * 0.065,
                              radius: actionRadius,
                              gradient: AppColors.verticalOrangeRed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.delete_outline_outlined,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    'edit.presentation.deleteAccount.title'
                                        .tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.012),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(actionRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: GradientButton(
                              onPressed: () =>
                                  _saveProfile(state.firebaseUser!.uid),
                              width: double.infinity,
                              height: height * 0.065,
                              radius: actionRadius,
                              child: Text(
                                'buttons.save'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.1),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required double width,
    required String displayName,
    required String username,
    required String email,
    String? avatarUrl,
  }) {
    final handle = username.isNotEmpty
        ? (username.startsWith('@') ? username : '@$username')
        : '';
    final avatarSize = (width * 0.14).clamp(56.0, 80.0).toDouble();
    final paddingValue = (width * 0.04).clamp(14.0, 20.0);

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: Colors.black,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: avatarSize * 0.55,
                    )
                  : null,
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'edit.presentation.deleteAccount.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('edit.presentation.deleteAccount.description'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('buttons.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('edit.presentation.deleteAccount.confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 🚧 SOLO VISUAL - NO HACE NADA AÚN
      if (!mounted) return;
      AlertGeneral.show(
        context,
        2,
        message: 'edit.presentation.deleteAccount.submitted'.tr(),
      );
    }
  }
}

class _EditProfileBackground extends StatelessWidget {
  const _EditProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.85),
                radius: 0.7,
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.75),
                radius: 0.9,
                colors: [
                  AppColors.primaryPink.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
