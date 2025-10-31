import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_background.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_image_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_options.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  Future<void> _confirmAndChangeLocation(String email) async {
    final svc = LocationService();
    final newLocation = await svc.initAndFetchAddress();
    if (newLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch current location')),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm location'),
        content: Text(
          "The current location is ${newLocation.city}, ${newLocation.country}. Is that correct?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location updated to ${newLocation.city}, ${newLocation.country}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Breakpoints
    final isMobile = screenWidth < 900;
    final isSmallScreen = screenWidth < 600;

    // Ancho mínimo para evitar errores de constraints
    const minWidth = 400.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authState.userProfile;
          if (user == null) {
            return const Center(
              child: Text(
                'No user data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

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

          return Stack(
            children: [
              const EditProfileBackground(),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: minWidth,
                      maxWidth: isMobile
                          ? screenWidth.clamp(minWidth, double.infinity)
                          : 1200,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 20 : 40,
                        right: isSmallScreen ? 20 : 40,
                        top: isSmallScreen ? 150 : 200,
                        bottom: 20,
                      ),
                      child: isMobile
                          ? Column(
                              children: [
                                _buildLeftColumn(
                                  isSmallScreen,
                                  user.avatarUrl,
                                  authState,
                                ),
                                const SizedBox(height: 30),
                                _buildRightColumn(context, authState, user),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLeftColumn(
                                  isSmallScreen,
                                  user.avatarUrl,
                                  authState,
                                ),
                                SizedBox(width: isSmallScreen ? 20 : 40),
                                Expanded(
                                  child: _buildRightColumn(
                                    context,
                                    authState,
                                    user,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftColumn(
    bool isSmallScreen,
    String? avatarUrl,
    AuthState authState,
  ) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        final containerWidth = screenWidth < 900
            ? double.infinity
            : (isSmallScreen ? 280.0 : 360.0);

        final imageSize = screenWidth < 900
            ? (screenWidth * 0.7).clamp(200.0, 320.0)
            : (isSmallScreen ? 250.0 : 320.0);

        String imageProfile = "";
        if (avatarUrl == null || avatarUrl.isEmpty) {
          imageProfile = "assets/images/Migozz.webp";
        } else {
          imageProfile = avatarUrl;
        }

        return SizedBox(
          width: containerWidth,
          child: EditProfileImageSection(
            isSmallScreen: isSmallScreen,
            imageSize: imageSize,
            avatarUrl: imageProfile,
            onDeleteAccount: () {},
            onSave: () => _saveProfile(authState.firebaseUser!.uid),
          ),
        );
      },
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    AuthState authState,
    dynamic user,
  ) {
    final userId = authState.firebaseUser?.uid;
    final formattedLocation = [
      if (user.location.city.isNotEmpty) user.location.city,
      if (user.location.country.isNotEmpty) user.location.country,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          hint: 'Full name',
          controller: nameCtrl,
          icon: Icons.account_box,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: 'Nickname',
          controller: usernameCtrl,
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: 'Email',
          controller: emailCtrl,
          icon: Icons.mail,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: 'Cell Phone',
          controller: phoneCtrl,
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: 'Date of birth',
          controller: birthCtrl,
          icon: Icons.calendar_today,
          readOnly: true,
          onTap: _pickBirthday,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: 'Gender',
          controller: genderCtrl,
          icon: Icons.transgender,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hint: formattedLocation.isNotEmpty ? formattedLocation : 'Location',
          icon: Icons.public,
          readOnly: true,
          onTap: () => _confirmAndChangeLocation(user.email),
        ),
        const SizedBox(height: 20),

        // 🔹 Botón Logout centrado y con el mismo tamaño que los inputs
        Center(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),
        EditProfileOptions(
          onEditRecord: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Use the app to change your audio")),
            );
          },
          onEditInterest: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditInterestsScreen()),
          ),
          onEditSocials: () {
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
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
