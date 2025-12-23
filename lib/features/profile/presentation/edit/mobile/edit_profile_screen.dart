import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_field.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_option_button.dart';
// import 'package:migozz_app/features/profile/presentation/edit/modules/edit_audio.dart';
// import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required TutorialKeys tutorialKeys});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthCtrl = TextEditingController();
  DateTime? _dob;
  String? _selectedGender;

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

  Future<void> _saveProfile(String userId) async {
    final editCubit = context.read<EditCubit>();
    try {
      final data = {
        'displayName': nameCtrl.text.trim(),
        'username': usernameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'gender': genderCtrl.text.trim(),
        'birthDate': _dob != null ? Timestamp.fromDate(_dob!) : null,
      };

      await editCubit.saveUserProfileField(userId: userId, updatedFields: data);

      if (mounted) {
        AlertGeneral.show(
          context,
          1,
          message: "edit.validations.updateProfile".tr(),
        );
      }
    } catch (e) {
      if (mounted) {
        AlertGeneral.show(
          context,
          4,
          message: '${"edit.validations.errorUpdateProfile".tr()} $e',
        );
      }
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

    final newLocation = await svc.initAndFetchAddress();

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
          "${newLocation.city}, ${newLocation.state}\n"
          "${newLocation.country}\n\n"
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
          message:
              '✅ ${"edit.validations.updateLocation".tr().replaceAll("\${newLocation.city}", newLocation.city).replaceAll("\${newLocation.country}", newLocation.country)}',
        );
      } catch (e) {
        if (!mounted) return;

        debugPrint('❌ [EditProfile] Error guardando ubicación: $e');

        AlertGeneral.show(
          context,
          4,
          message: "edit.validations.errorUpdateLocation".tr().replaceAll(
            "\$e",
            e.toString(),
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
      case 'other':
      case 'otro':
        return 'other';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'edit.presentation.title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => context.pop(),
        // ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.close, color: Colors.red),
        //     onPressed: () => context.pop(),
        //   ),
        // ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isTablet = width > 600;

          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state.isLoadingProfile) {
                return Center(
                  child: LoaderDialog(
                    message: 'edit.presentation.loadingProfile'.tr(),
                  ),
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
                formattedLocation = 'edit.presentation.locationNotSet'.tr();
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
                'other': 'edit.presentation.genderOptions.other'.tr(),
              };

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? width * 0.2 : width * 0.08,
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.02),

                    ProfileField(
                      hint: 'edit.presentation.fields.fullName'.tr(),
                      controller: nameCtrl,
                      icon: Icons.account_box,
                    ),
                    ProfileField(
                      hint: 'edit.presentation.fields.nickname'.tr(),
                      controller: usernameCtrl,
                      icon: Icons.alternate_email,
                    ),
                    ProfileField(
                      hint: 'edit.presentation.fields.email'.tr(),
                      controller: emailCtrl,
                      icon: Icons.mail,
                      readOnly: true,
                    ),
                    ProfileField(
                      hint: 'edit.presentation.fields.cellPhone'.tr(),
                      controller: phoneCtrl,
                      icon: Icons.phone,
                    ),
                    ProfileField(
                      hint: 'edit.presentation.fields.dateOfBirth'.tr(),
                      controller: birthCtrl,
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _pickBirthday,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        iconEnabledColor: Colors.white,
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: const Icon(
                              Icons.transgender,
                              color: Colors.white,
                            ),
                          ),
                          hintText: 'edit.presentation.fields.gender'.tr(),
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                        items: genderOptions.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(color: Colors.white),
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
                    ),
                    ProfileField(
                      hint: formattedLocation,
                      icon: Icons.public,
                      readOnly: true,
                      onTap: () => _confirmAndChangeLocation(user.email),
                    ),

                    SizedBox(height: height * 0.025),

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
                      onTap: () async => FirebaseAuth.instance.signOut(),
                    ),

                    SizedBox(height: height * 0.04),

                    GradientButton(
                      onPressed: _confirmDeleteAccount,
                      width: double.infinity,
                      height: height * 0.065,
                      radius: width * 0.02,
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
                            'edit.presentation.deleteAccount.title'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: height * 0.012),

                    GradientButton(
                      onPressed: () => _saveProfile(state.firebaseUser!.uid),
                      width: double.infinity,
                      height: height * 0.065,
                      radius: width * 0.02,
                      child: Text(
                        'buttons.save'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.14),
                  ],
                ),
              );
            },
          );
        },
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
