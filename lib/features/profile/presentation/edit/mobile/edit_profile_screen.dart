import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_avatar.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_field.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/profile_option_button.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_audio.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

// TODO: usar JSON
class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _uploading = false;
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthCtrl = TextEditingController();
  DateTime? _dob;

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

  Future<void> _changeAvatar(String userId) async {
    final editCubit = context.read<EditCubit>();
    setState(() => _uploading = true);
    try {
      await editCubit.changeAvatar(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("edit.validations.updateProfilePic".tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${"edit.validations.updateProfilePic".tr()} $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("edit.validations.updateProfile".tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"edit.validations.errorUpdateProfile".tr()} $e'),
          ),
        );
      }
    }
  }

  // MÉTODO ACTUALIZADO CON GUARDADO COMPLETO
  Future<void> _confirmAndChangeLocation(String email) async {
    final svc = LocationService();

    // Mostrar loading mientras detecta ubicación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("edit.validations.detectLocation".tr()),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final newLocation = await svc.initAndFetchAddress();

    if (newLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("edit.validations.errorDetecLocation".tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm location'),
        content: Text(
          "We detected you're in:\n\n"
          "${newLocation.city}, ${newLocation.state}\n"
          "${newLocation.country}\n\n"
          "Is that correct?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    // GUARDAR UBICACIÓN SI EL USUARIO CONFIRMÓ
    if (confirm == true) {
      if (!mounted) return;

      try {
        final editCubit = context.read<EditCubit>();
        final userId = context.read<AuthCubit>().state.firebaseUser?.uid;

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Preparar datos de ubicación para Firestore
        final locationData = {
          'location': newLocation.toMap(), //  LocationDTO tiene este método
        };

        debugPrint('💾 [EditProfile] Guardando ubicación en Firestore...');
        debugPrint('   • UserId: $userId');
        debugPrint('   • Data: $locationData');

        // Guardar en Firestore
        // El EditCubit automáticamente refrescará el AuthCubit después de guardar
        await editCubit.saveUserProfileField(
          userId: userId,
          updatedFields: locationData,
        );

        if (!mounted) return;

        debugPrint('✅ [EditProfile] Ubicación guardada exitosamente');

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Location updated to ${newLocation.city}, ${newLocation.country}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // El perfil ya se refrescó automáticamente gracias al EditCubit
        // La UI se actualizará automáticamente gracias al BlocBuilder
      } catch (e) {
        if (!mounted) return;

        debugPrint('❌ [EditProfile] Error guardando ubicación: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Usuario canceló
      debugPrint('🚫 [EditProfile] Usuario canceló el cambio de ubicación');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isTablet = width > 600;

          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state.isLoadingProfile) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = state.userProfile;
              if (user == null) {
                return const Center(
                  child: Text(
                    'No user data',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              String imageProfile = "";

              if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
                imageProfile = "assets/images/Migozz.webp";
              } else {
                imageProfile = user.avatarUrl!;
              }

              // inicializa los controladores solo una vez
              if (nameCtrl.text.isEmpty) {
                nameCtrl.text = user.displayName;
                usernameCtrl.text = user.username;
                emailCtrl.text = user.email;
                phoneCtrl.text = user.phone ?? '';
                genderCtrl.text = user.gender;

                if (user.birthDate != null) {
                  _dob = user.birthDate;
                  birthCtrl.text =
                      "${user.birthDate!.year}-${user.birthDate!.month.toString().padLeft(2, '0')}-${user.birthDate!.day.toString().padLeft(2, '0')}";
                }
              }

              // Formatear ubicación - ahora maneja LocationDTO.empty()
              String formattedLocation = 'Location not set';

              if (user.location.isEmpty) {
                formattedLocation = 'Location not set';
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

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? width * 0.2 : width * 0.08,
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.02),

                    ProfileAvatar(
                      avatarUrl: imageProfile,
                      uploading: _uploading,
                      onEdit: () {
                        _changeAvatar(state.firebaseUser!.uid);
                      },
                    ),
                    SizedBox(height: height * 0.025),

                    /// Campos del perfil
                    ProfileField(
                      hint: 'Full name',
                      controller: nameCtrl,
                      icon: Icons.account_box,
                    ),
                    ProfileField(
                      hint: 'Nickname',
                      controller: usernameCtrl,
                      icon: Icons.alternate_email,
                    ),
                    ProfileField(
                      hint: 'Email',
                      controller: emailCtrl,
                      icon: Icons.mail,
                      readOnly: true,
                    ),
                    ProfileField(
                      hint: 'Cell Phone',
                      controller: phoneCtrl,
                      icon: Icons.phone,
                    ),
                    ProfileField(
                      hint: 'Date of birth',
                      controller: birthCtrl,
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _pickBirthday,
                    ),
                    ProfileField(
                      hint: 'Gender',
                      controller: genderCtrl,
                      icon: Icons.transgender,
                    ),
                    ProfileField(
                      hint: formattedLocation,
                      icon: Icons.public,
                      readOnly: true,
                      onTap: () => _confirmAndChangeLocation(user.email),
                    ),

                    SizedBox(height: height * 0.025),

                    /// Botones
                    ProfileOptionButton(
                      icon: Icons.play_circle_outline,
                      text: 'Edit Record',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditRecordScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionButton(
                      icon: Icons.handshake_outlined,
                      text: 'Edit My Interests',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditInterestsScreen(),
                        ),
                      ),
                    ),
                    ProfileOptionButton(
                      icon: Icons.share_outlined,
                      text: 'Edit Socials',
                      onTap: () {
                        final userId = state.firebaseUser?.uid;
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: User not logged in'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final editCubit = context.read<EditCubit>();
                        editCubit.setEditItem(EditItem.socialEcosystem);

                        debugPrint(
                          '🔹 [EditProfileScreen] Navegando a MoreUserDetails en modo EDIT',
                        );
                        debugPrint('🔹 userId: $userId');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: editCubit,
                              child: MoreUserDetails(
                                pageIndicator: 0,
                                mode: MoreUserDetailsMode.edit,
                                userId: userId,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ProfileOptionButton(
                      icon: Icons.logout,
                      text: 'Logout',
                      onTap: () async => FirebaseAuth.instance.signOut(),
                    ),

                    SizedBox(height: height * 0.04),

                    GradientButton(
                      onPressed: () {},
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
                          const Text(
                            'Delete Account',
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
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
