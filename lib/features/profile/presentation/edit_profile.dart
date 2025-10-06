import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:migozz_app/features/auth/services/media_service.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/profile/presentation/config/edit_my_interest.dart';
import 'package:migozz_app/features/profile/presentation/config/edit_social.dart';
import 'package:migozz_app/features/profile/presentation/config/edit_audio.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Map<String, dynamic>? _userDoc;
  bool _uploading = false;
  bool _dirty = false; // Douglas: hubo cambios en esta vista - SOL: tambien hice cambios :D
  DateTime? _dob; // Se llenará desde Firestore (Timestamp o String ISO)
  bool _hasChanges = false;
  bool _allFilled = false;
  late Map<String, dynamic> _originalData;
  

  @override
  void initState() {
    super.initState();
    _loadUser();

  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (data == null) return;

      DateTime? parsedDob;
      final rawDob = data['dob'];
      if (rawDob is Timestamp) {
        parsedDob = rawDob.toDate().toUtc();
      } else if (rawDob is String && rawDob.isNotEmpty) {
        final p = rawDob.split('-');
        if (p.length == 3) {
          parsedDob = DateTime.utc(
            int.parse(p[0]),
            int.parse(p[1]),
            int.parse(p[2]),
          );
        }
      }

      if (mounted) {
        setState(() {
          _userDoc = data;
          _dob = parsedDob;

          // Llenamos los controladores para poder cargarlos correctamente
          _originalData = {
            'displayName': data['displayName'] ?? '',
            'username': data['username'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['phone'] ?? '',
            'gender': data['gender'] ?? '',
          };
          displayNameController.text = data['displayName'] ?? '';
          usernameController.text = data['username'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          genderController.text = data['gender'] ?? '';
          birthController.text = _dob != null
              ? "${_dob!.year.toString().padLeft(4, '0')}-"
                "${_dob!.month.toString().padLeft(2, '0')}-"
                "${_dob!.day.toString().padLeft(2, '0')}"
              : '';
        });
        for (var controller in [
          displayNameController,
          usernameController,
          emailController,
          phoneController,
          genderController
        ]) {
          controller.addListener(_checkForChanges);
        }
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    }
  }

    void _checkForChanges() {
    if (_userDoc == null) return;

    final currentValues = {
      'displayName': displayNameController.text.trim(),
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'gender': genderController.text.trim(),
    };

    // Verifica que todos los campos tengan contenido
    _allFilled = currentValues.values.every((v) => v.isNotEmpty);

    // Detecta si hay alguna diferencia con los datos originales
    _hasChanges = currentValues.entries.any(
      (e) => e.value != _originalData[e.key],
    );

    setState(() {}); // Esto actualiza el botón "save" dinámicamente
  }

  @override
  void dispose() {
    for (var controller in [
      displayNameController,
      usernameController,
      emailController,
      phoneController,
      genderController
    ]) {
      controller.removeListener(_checkForChanges);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final location = (_userDoc?['location'] as Map?) ?? const {};
    final city = location['city'] ?? '';
    final avatarUrl = (_userDoc?['avatarUrl'] as String?);
    String dobLabel() { // DOB formateado para UI
      if (_dob == null) return 'Date of birth';
      return "${_dob!.year.toString().padLeft(4,'0')}-"
             "${_dob!.month.toString().padLeft(2,'0')}-"
             "${_dob!.day.toString().padLeft(2,'0')}";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => context.pop(_dirty ? 'updated' : null),
          ),
        ],
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(_dirty ? 'updated' : null),
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: 0,
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: screenWidth * 0.36,
                      height: screenWidth * 0.36,
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/profileBackground.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/profileBackground.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploading ? null : _onChangeAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.048,
                            backgroundColor: Colors.deepPurple,
                          ),
                          CircleAvatar(
                            radius: screenWidth * 0.044,
                            backgroundColor: Colors.pinkAccent,
                            child: _uploading
                                ? SizedBox(
                                    width: screenWidth * 0.036,
                                    height: screenWidth * 0.036,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.edit,
                                    size: screenWidth * 0.042,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              
              listBuildBox(
                controller: displayNameController,
                text: 'Name',
                icon: Icons.account_box,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ), 
              listBuildBox(
                controller: usernameController,
                text: 'Nickname',
                icon: Icons.alternate_email,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                controller: emailController,
                text: 'Email',
                icon: Icons.mail,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                controller: phoneController,
                text: 'Phone',
                icon: Icons.phone,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: dobLabel(),
                icon: Icons.calendar_today,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
                isReadingOnly: true,
              ),
              listBuildBox(
                controller: genderController,
                text: 'Gender',
                icon: Icons.transgender,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: city.toString().isEmpty ? 'Location' : city.toString(),
                icon: Icons.public,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
                isReadingOnly: true,
              ),
              SizedBox(height: screenHeight * 0.025),
              // Sección de opciones adicionales
              Column(
                children: [
                  bottomOptions(
                    text: ' Edit Record',
                    icon: Icons.play_circle_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditRecordScreen()),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  bottomOptions(
                    text: ' Logout',
                    icon: Icons.logout,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      // ignore: use_build_context_synchronously
                      if (mounted) context.go('/login');
                    },
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  bottomOptions(
                    text: ' Edit My Interes',
                    icon: Icons.handshake_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditInterestsScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  bottomOptions(
                    text: ' Edit Socials',
                    icon: Icons.share_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditSocialScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

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

              Opacity(
                opacity: (_hasChanges && _allFilled) ? 1 : 0.5,
                child: GradientButton(
                  onPressed: (_hasChanges && _allFilled)
                      ? () async {
                          await saveChanges();
                          if (!context.mounted) return;
                          context.pop('updated');
                        }
                      : null,
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
              ),
              SizedBox(
                height: screenHeight * 0.025,
              ), // Espacio adicional al final
            ],
          ),
        ),
      ),
    );
  }

  Widget profileImage({required Image source, double radius = 70}) {
    return ClipOval(
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.15, 0, 0, 0, 0, // R
          0, 1.15, 0, 0, 0, // G
          0, 0, 1.25, 0, 0, // B
          0, 1, 1, 2, 0, // A
        ]),
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.asset(
            'assets/images/profileBackground.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget listBuildBox({
    required String text,
    Align? align, // Opcional
    IconData? icon, // Opcional
    Color colorbackground = Colors.white, // Valores por defecto
    Color textColorInside = Colors.black,
    Color iconColorInside = Colors.black,
    TextEditingController? controller,
    bool isReadingOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          86,
          153,
          149,
          149,
        ).withValues(alpha: 0.08), // Fondo blanco muy transparente
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3), // Borde gris más visible
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8), // Bordes redondeados
      ),
      child: TextField( // Cambio a TextField para manejo de cambios por parte del usuario
      controller: controller,
      style: TextStyle(
        color: iconColorInside
      ),
      readOnly: isReadingOnly,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(0, 14, 0, 0),
          prefixIcon: Icon(icon, color: iconColorInside),
          hintStyle: TextStyle(color: iconColorInside.withValues(alpha: 8.0)),
          hintText: text, 
        ),
      ),
    );
  }

  final displayNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final birthController = TextEditingController(); // DOB: sincronizado en _loadUser
  // final cityController = TextEditingController(); // Prefiero manejarlo con una "Georreferenciación autumatica"

  Future<void> saveChanges() async {
  final currentUser = FirebaseAuth.instance.currentUser; // usuario real
  if (currentUser == null) return;

  final newDisplayName = displayNameController.text.trim();
  final newUsername = usernameController.text.trim();
  final newEmail = emailController.text.trim();
  final newPhone = phoneController.text.trim();
  final newGender = genderController.text.trim();

  final oldData = _userDoc ?? {};

  Map<String, dynamic> updates = {};

  if (newDisplayName.isNotEmpty && newDisplayName != oldData['displayName']) {
    updates['displayName'] = newDisplayName;
  }
  if (newUsername.isNotEmpty && newUsername != oldData['username']) {
    updates['username'] = newUsername;
  }
  if (newEmail.isNotEmpty && newEmail != oldData['email']) {
    updates['email'] = newEmail;
  }
  if (newPhone.isNotEmpty && newPhone != oldData['phone']) {
    updates['phone'] = newPhone;
  }
  if (newGender.isNotEmpty && newGender != oldData['gender']) {
    updates['gender'] = newGender;
  }

  if (updates.isNotEmpty) {
    
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);  
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }

    await _loadUser();
    setState(() => _dirty = true);
  }
    // El cambio de fecha es mas complejo, luego lo resuelvo  [SOL]

  Widget bottomOptions({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          return Row(
            children: [
              Padding(padding: EdgeInsets.only(right: screenWidth * 0.04)),
              Icon(
                icon,
                color: Colors.white.withAlpha(200),
                size: screenWidth * 0.055,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onChangeAvatar() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final email = (_userDoc?['email'] as String?) ?? user.email ?? user.uid;

      setState(() => _uploading = true);

      // Subir usando el mismo servicio que en registro
      final mediaService = UserMediaService();
      final urls = await mediaService.uploadFilesTemporarily(
        email: email,
        files: {MediaType.avatar: File(xfile.path)},
      );
      final newUrl = urls[MediaType.avatar];
      if (newUrl == null) return;

      // Actualizar en test y users (merge)
      final now = FieldValue.serverTimestamp();
      final db = FirebaseFirestore.instance;
      await db.collection('users').doc(user.uid).set({
        'avatarUrl': newUrl,
        'updatedAt': now,
      }, SetOptions(merge: true));
      await db.collection('users').doc(user.uid).set({
        'avatarUrl': newUrl,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _userDoc = {...?_userDoc, 'avatarUrl': newUrl};
          _uploading = false;
          _dirty = true;
        });
        // notificar a la pantalla anterior que hay cambios
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
}