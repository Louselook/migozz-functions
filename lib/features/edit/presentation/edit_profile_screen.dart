import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/features/edit/components/edit_profile_controller.dart';
import 'package:migozz_app/features/edit/components/profile_avatar.dart';
import 'package:migozz_app/features/edit/components/profile_field.dart';
import 'package:migozz_app/features/edit/components/profile_option_button.dart';
import 'package:migozz_app/features/edit/components/user_profile.dart';
import 'package:migozz_app/features/edit/presentation/edit_audio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/features/edit/presentation/edit_my_interest.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _controller = EditProfileController();
  UserProfile? _user;
  bool _loading = true;
  bool _uploading = false;
  bool _dirty = false;

  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthCtrl = TextEditingController();

  DateTime? _dob;

  String get formattedLocation {
    if (_user == null) return 'Location';
    final city = _user!.city;
    final country = _user!.country;
    if (city == null && country == null) return 'Location';
    if (city != null && country != null) return '$city, $country';
    return city ?? country ?? 'Location';
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _pickBirthday() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2010, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
        birthCtrl.text =
            "${picked.year.toString().padLeft(4, '0')}-"
            "${picked.month.toString().padLeft(2, '0')}-"
            "${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _loadUser() async {
    final user = await _controller.loadUser();
    if (user == null) return;

    // -------------------
    // Parseo DOB (igual a tu implementación)
    // -------------------
    DateTime? parsedDob;
    final dynamic rawDob = user.dob; // puede ser Timestamp, DateTime, String, int, o null

    if (rawDob == null) {
      parsedDob = null;
    } else if (rawDob is Timestamp) {
      // Timestamp de Firestore
      parsedDob = rawDob.toDate().toUtc();
    } else if (rawDob is DateTime) {
      // Ya viene como DateTime
      parsedDob = rawDob.toUtc();
    } else if (rawDob is String && rawDob.isNotEmpty) {
      // Formato "YYYY-MM-DD"
      final parts = rawDob.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          parsedDob = DateTime.utc(y, m, d);
        }
      }
    } else if (rawDob is int) {
      // Epoch: detectamos si viene en ms o en s
      final absVal = rawDob.abs();
      if (absVal > 9999999999) {
        // probable milliseconds
        parsedDob = DateTime.fromMillisecondsSinceEpoch(rawDob, isUtc: true);
      } else {
        // probable seconds
        parsedDob = DateTime.fromMillisecondsSinceEpoch(
          rawDob * 1000,
          isUtc: true,
        );
      }
    } else {
      parsedDob = null;
    }

    // -------------------
    // Llenar UI con datos del user
    // -------------------
    birthCtrl.text = parsedDob != null
        ? "${parsedDob.year.toString().padLeft(4, '0')}-"
          "${parsedDob.month.toString().padLeft(2, '0')}-"
          "${parsedDob.day.toString().padLeft(2, '0')}"
        : '';

    setState(() {
      _user = user;
      _dob = parsedDob;
      _loading = false;

      nameCtrl.text = user.displayName ?? '';
      usernameCtrl.text = user.username ?? '';
      emailCtrl.text = user.email ?? '';
      phoneCtrl.text = user.phone ?? '';
      genderCtrl.text = user.gender ?? '';
    });

    // -------------------
    // AQUÍ: pedir al CUBIT que cargue las socials desde Firestore
    // -------------------
    // Nota: comprobamos mounted antes de usar context después de await
    final uid = FirebaseAuth.instance.currentUser?.uid ?? user.id;

    try {
      // Opcional: si quieres mostrar loader local para la carga de socials,
      // activa una bandera antes y la apagas después.
      // setState(() => _loadingSocials = true);

      // 1) Esperar a que el cubit termine (útil si tu UI depende de esto inmediatamente)
      await context.read<RegisterCubit>().loadSocialsFromFirestore(uid: uid);

      // 2) Si prefieres no bloquear UI, en vez de await puedes:
      // context.read<AuthCubit>().loadSocialsFromFirestore(uid: uid); // fire-and-forget

      // After awaiting any async, check mounted before touching context/state
      if (!mounted) return;

      // opcional: actualizar algo en la UI local si lo necesitas,
      // por ejemplo sincronizar un selectedSocials local desde el cubit.
      // final cubitState = context.read<AuthCubit>().state;
      // setState(() => selectedSocials = cubitState.socialKeys);

    } catch (e, st) {
      debugPrint('🔥 Error delegando loadSocials al cubit: $e\n$st');
      // fallback: nada o limpiar UI localmente
      // setState(() => selectedSocials = {});
    } finally {
      // setState(() => _loadingSocials = false);
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final current = FirebaseAuth.instance.currentUser;
      if (current == null || _user == null) return;

      setState(() => _uploading = true);

      final mediaService = UserMediaService();

      // Asegurar que los archivos estén en la carpeta correcta (UID)
      await mediaService.associateMediaToUid(
        uid: current.uid,
        email: _user!.email ?? '',
      );

      // Ahora subimos la imagen directamente al UID correcto
      final urls = await mediaService.uploadFiles(
        uid: current.uid,
        files: {MediaType.avatar: File(xfile.path)},
      );

      final newUrl = urls[MediaType.avatar];
      if (newUrl == null) return;

      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
        {'avatarUrl': newUrl, 'updatedAt': now},
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _user = _user!.copyWith(avatarUrl: newUrl);
          _uploading = false;
          _dirty = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating photo: $e')));
      }
    }
    }

  Future<void> _saveChanges() async {
    if (_user == null) return;

    final updatedUser = _user!.copyWith(
      displayName: nameCtrl.text.trim(),
      username: usernameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      gender: genderCtrl.text.trim(),
      dob: _dob,
    );

    await _controller.saveUserProfile(updatedUser);
    setState(() => _dirty = true);

    if (mounted) {
      context.pop('updated');
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _confirmAndChangeLocation() async {
    try {
      final svc = LocationService();
      final newLocation = await svc.initAndFetchAddress();

      if (newLocation == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch current location')),
        );
        return;
      }

      // Mostrar confirmación con la ubicación detectada
      final confirm = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm location'),
            content: Text(
              "The current location is ${newLocation.city}, ${newLocation.country}. Is that correct?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Si el usuario confirmó, actualizamos la UI (pero no guardamos aún)
      if (confirm == true) {
        setState(() {
          _user = _user!.copyWith(
            city: newLocation.city,
            country: newLocation.country,
          );
          _dirty = true;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error getting location')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => context.pop(_dirty ? 'updated' : null),
          ),
        ],
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(_dirty ? 'updated' : null),
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            children: [
              // FOTO DE PERFIL
              ProfileAvatar(
                avatarUrl: _user?.avatarUrl,
                uploading: _uploading,
                onEdit: _changeAvatar,
              ),
              SizedBox(height: screenHeight * 0.025),

              // CAMPOS DE PERFIL
              ProfileField(
                hint: _user?.displayName ?? 'Full name',
                controller: nameCtrl,
                icon: Icons.account_box,
              ),
              ProfileField(
                hint: _user?.username ?? 'Nickname',
                controller: usernameCtrl,
                icon: Icons.alternate_email,
              ),
              ProfileField(
                hint: _user?.email ?? 'Email',
                controller: emailCtrl,
                icon: Icons.mail,
              ),
              ProfileField(
                hint: _user?.phone ?? 'Cell Phone',
                controller: phoneCtrl,
                icon: Icons.phone,
              ),
              ProfileField(
                hint: 'Date of birth',
                controller: birthCtrl,
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: _pickBirthday, // función que abre el date picker
              ),
              ProfileField(
                hint: _user?.gender ?? 'Gender',
                controller: genderCtrl,
                icon: Icons.transgender,
              ),
              ProfileField(
                hint: formattedLocation,
                icon: Icons.public,
                readOnly: true,
                onTap: _confirmAndChangeLocation,
                displayValue: formattedLocation,
              ),
              SizedBox(height: screenHeight * 0.025),

              // OPCIONES ADICIONALES
              Column(
                children: [
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
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      context.go('/login');
                    },
                  ),
                  ProfileOptionButton(
                    icon: Icons.handshake_outlined,
                    text: 'Edit My Interes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditInterestsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileOptionButton(
                    icon: Icons.share_outlined,
                    text: 'Edit Socials',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MoreUserDetails(pageIndicator: 0,),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),

              // BOTONES DE ACCIÓN
              GradientButton(
                onPressed: () {},
                width: double.infinity,
                height: screenHeight * 0.065,
                radius: screenWidth * 0.02,
                gradient: AppColors.verticalOrangeRed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_outlined,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              GradientButton(
                onPressed: _saveChanges,
                width: double.infinity,
                height: screenHeight * 0.065,
                radius: screenWidth * 0.02,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
            ],
          ),
        ),
      ),
    );
  }
}
