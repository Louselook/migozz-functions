import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/components/edit_location_bottom_sheet.dart';

/// Configuration / Settings page — accessed from SideMenu "Configuration".
/// Contains: personal info form fields, save, logout, delete account.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Form controllers
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthCtrl = TextEditingController();
  DateTime? _dob;
  String? _selectedGender;
  UserDTO? _initialUser;
  bool _uploading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
    bioCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    genderCtrl.dispose();
    birthCtrl.dispose();
    super.dispose();
  }

  // ─── HELPERS ───

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
      default:
        return null;
    }
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
      final newUsername = usernameCtrl.text.trim().toLowerCase();
      final currentUsername = _initialUser?.username.toLowerCase() ?? '';

      if (newUsername != currentUsername && newUsername.isNotEmpty) {
        final userService = UserService(UserMediaService());
        final isTaken = await userService.isUsernameTaken(
          newUsername,
          excludeUserId: userId,
        );
        if (isTaken) {
          if (mounted) {
            AlertGeneral.show(
              context,
              4,
              message: 'edit.validations.usernameTaken'.tr(),
              autoDismissAfter: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      final data = {
        'displayName': nameCtrl.text.trim(),
        'username': newUsername,
        'phone': phoneCtrl.text.trim(),
        'gender': genderCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'birthDate': _dob != null ? Timestamp.fromDate(_dob!) : null,
      };

      await editCubit.saveUserProfileField(userId: userId, updatedFields: data);

      if (_initialUser != null) {
        _initialUser = _initialUser!.copyWith(
          displayName: nameCtrl.text.trim(),
          username: newUsername,
          phone: phoneCtrl.text.trim(),
          gender: genderCtrl.text.trim(),
          bio: bioCtrl.text.trim(),
          birthDate: _dob,
        );
      }

      if (mounted) {
        AlertGeneral.show(
          context,
          1,
          message: 'edit.validations.updateProfile'.tr(),
          autoDismissAfter: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) {
        AlertGeneral.show(
          context,
          4,
          message: '${'edit.validations.errorUpdateProfile'.tr()} $e',
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    if (userId == null) return;

    final editCubit = context.read<EditCubit>();
    setState(() => _uploading = true);
    try {
      final wasChanged = await editCubit.changeAvatar(userId, context);
      if (mounted && wasChanged) {
        AlertGeneral.show(
          context,
          1,
          message: 'profile.customization.uploadingProfilePicture.success'.tr(),
        );
      }
    } catch (e) {
      if (mounted) {
        AlertGeneral.show(
          context,
          4,
          message:
              '${'profile.customization.uploadingProfilePicture.error'.tr()}$e',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmAndChangeLocation(String email) async {
    final userId = context.read<AuthCubit>().state.firebaseUser?.uid;
    if (userId == null) {
      AlertGeneral.show(
        context,
        4,
        message: 'edit.validations.errorUserLogin'.tr(),
      );
      return;
    }

    final currentUser = context.read<AuthCubit>().state.userProfile;
    final currentLocation = currentUser?.location ?? LocationDTO.empty();
    final editCubit = context.read<EditCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditLocationBottomSheet(
        currentLocation: currentLocation,
        onSave: (LocationDTO newLocation) async {
          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'location': newLocation.toMap()},
            );
            if (mounted) {
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
            }
          } catch (e) {
            if (mounted) {
              AlertGeneral.show(
                context,
                4,
                message: 'edit.validations.errorUpdateLocation'.tr(
                  namedArgs: {'error': e.toString()},
                ),
              );
            }
          }
        },
        onRemove: () async {
          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'location': LocationDTO.empty().toMap()},
            );
            if (mounted) {
              AlertGeneral.show(
                context,
                1,
                message: 'edit.editLocation.locationRemoved'.tr(),
              );
            }
          } catch (e) {
            if (mounted) {
              AlertGeneral.show(
                context,
                4,
                message: 'edit.validations.errorUpdateLocation'.tr(
                  namedArgs: {'error': e.toString()},
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'edit.presentation.deleteAccount.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'edit.presentation.deleteAccount.description'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('buttons.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('edit.presentation.deleteAccount.confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      AlertGeneral.show(
        context,
        2,
        message: 'edit.presentation.deleteAccount.submitted'.tr(),
      );
    }
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),

          // SideMenu
          const Positioned(top: 0, bottom: 0, left: 0, child: SideMenu()),

          // Main content
          Positioned(
            top: 0,
            bottom: 0,
            left: 70,
            right: 0,
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState.isLoadingProfile) {
                  return Center(
                    child: LoaderDialog(
                      message: 'edit.presentation.loadingProfile'.tr(),
                    ),
                  );
                }

                final user = authState.userProfile;
                if (user == null) {
                  return Center(
                    child: Text(
                      'edit.presentation.errorUserEmpty'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Initialize form fields once
                if (nameCtrl.text.isEmpty) {
                  _initialUser = user;
                  nameCtrl.text = user.displayName;
                  usernameCtrl.text = user.username;
                  bioCtrl.text = user.bio ?? '';
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

                final contentWidth = (screenWidth - 70).clamp(400.0, 900.0);

                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── BACK + TITLE ───
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.go('/profile'),
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'edit.presentation.title'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ─── HEADER CARD ───
                          _buildHeaderCard(user),
                          const SizedBox(height: 24),

                          // ─── PERSONAL INFO CARD ───
                          _buildPersonalInfoCard(user, authState),
                          const SizedBox(height: 24),

                          // ─── SAVE BUTTON ───
                          GradientButton(
                            onPressed: () =>
                                _saveProfile(authState.firebaseUser!.uid),
                            width: double.infinity,
                            height: 54,
                            radius: 12,
                            child: Text(
                              'buttons.save'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ─── LOGOUT ───
                          _buildLogoutButton(context),
                          const SizedBox(height: 12),

                          // ─── DELETE ACCOUNT ───
                          GradientButton(
                            onPressed: _confirmDeleteAccount,
                            width: double.infinity,
                            height: 54,
                            radius: 12,
                            gradient: AppColors.verticalOrangeRed,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'edit.presentation.deleteAccount.title'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── WIDGET BUILDERS ───
  // ═══════════════════════════════════════════════

  Widget _buildBackground() {
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

  Widget _buildHeaderCard(UserDTO user) {
    final avatarUrl = user.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final handle = user.username.isNotEmpty
        ? (user.username.startsWith('@') ? user.username : '@${user.username}')
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.black,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar
                      ? Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 50,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _uploading ? null : _changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Change photo text
          GestureDetector(
            onTap: _uploading ? null : _changeAvatar,
            child: Text(
              _uploading
                  ? 'profile.customization.uploadingProfilePicture.uploading'
                        .tr()
                  : 'profile.customization.uploadingProfilePicture.title'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            user.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              handle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserDTO user, AuthState authState) {
    final formattedLocation = _buildLocationText(user);

    final genderOptions = <String, String>{
      'male': 'edit.presentation.genderOptions.male'.tr(),
      'female': 'edit.presentation.genderOptions.female'.tr(),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'edit.presentation.fields.fullName'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildFormField(
            controller: nameCtrl,
            icon: Icons.account_box,
            hint: 'edit.presentation.fields.fullName'.tr(),
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: usernameCtrl,
            icon: Icons.alternate_email,
            hint: 'edit.presentation.fields.nickname'.tr(),
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: bioCtrl,
            icon: Icons.edit_note,
            hint: 'edit.presentation.fields.bio'.tr(),
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: emailCtrl,
            icon: Icons.mail,
            hint: 'edit.presentation.fields.email'.tr(),
            readOnly: true,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: phoneCtrl,
            icon: Icons.phone,
            hint: 'edit.presentation.fields.cellPhone'.tr(),
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: birthCtrl,
            icon: Icons.calendar_today,
            hint: 'edit.presentation.fields.dateOfBirth'.tr(),
            readOnly: true,
            onTap: _pickBirthday,
          ),
          const SizedBox(height: 14),

          // Gender dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
              ),
              dropdownColor: Colors.black.withValues(alpha: 0.92),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.transgender,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              hint: Text(
                'edit.presentation.fields.gender'.tr(),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              items: genderOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                  genderCtrl.text = value ?? '';
                });
              },
            ),
          ),
          const SizedBox(height: 14),

          // Location
          _buildFormField(
            hint: formattedLocation.isNotEmpty
                ? formattedLocation
                : 'edit.presentation.fields.location'.tr(),
            icon: Icons.public,
            readOnly: true,
            onTap: () => _confirmAndChangeLocation(user.email),
          ),
        ],
      ),
    );
  }

  String _buildLocationText(UserDTO user) {
    if (user.location.isEmpty) return '';
    final parts = <String>[];
    if (user.location.city.isNotEmpty) parts.add(user.location.city);
    if (user.location.state.isNotEmpty) parts.add(user.location.state);
    if (user.location.country.isNotEmpty) parts.add(user.location.country);
    return parts.join(', ');
  }

  Widget _buildFormField({
    TextEditingController? controller,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await AlertGeneral.showConfirm(
            context,
            title: 'edit.presentation.logOut'.tr(),
            message: 'edit.presentation.logOutConfirmation'.tr(),
          );
          if (confirm && context.mounted) {
            showProfileLoader(context, type: LoaderType.logout);
            try {
              await context.read<AuthCubit>().logout();
            } finally {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          }
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(
          'edit.presentation.logOut'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
