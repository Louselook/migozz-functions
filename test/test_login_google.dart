import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/components/google_button.dart';

class TestLoginGoogle extends StatefulWidget {
  const TestLoginGoogle({super.key});

  @override
  TestLoginGoogleState createState() => TestLoginGoogleState();
}

class TestLoginGoogleState extends State<TestLoginGoogle> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      setState(() {
        _user = result.user;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mostrar info del usuario si está logueado
              if (_user != null) ...[
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _user!.photoURL != null
                      ? NetworkImage(_user!.photoURL!)
                      : null,
                  child: _user!.photoURL == null
                      ? Icon(Icons.person, size: 50, color: AppColors.grey)
                      : null,
                ),
                SizedBox(height: 20),
                PrimaryText(_user!.displayName ?? 'Usuario'),
                SizedBox(height: 10),
                SecondaryText(_user!.email ?? '', color: AppColors.grey),
                SizedBox(height: 30),
              ],

              // Botón de Google
              googleButton(
                onPressed: _user == null ? _signInWithGoogle : _signOut,
                text: _user == null ? 'Google' : 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
