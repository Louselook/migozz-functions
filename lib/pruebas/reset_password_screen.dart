import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:migozz_app/pruebas/auth_home_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  // Cambiar contraseña y login automático
  Future<void> changePasswordAndLogin() async {
    setState(() {
      loading = true;
    });

    final url = Uri.parse(
      'http://10.0.2.2:8000/change-password',
    ); // ajusta según tu entorno

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'new_password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // Contraseña cambiada, iniciar sesión automáticamente
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Navegar a Home
        if (context.mounted) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const AuthHomeScreen()),
          );
        }
      } else {
        final error = jsonDecode(response.body)['detail'];
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo del usuario',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: changePasswordAndLogin,
                    child: const Text('Cambiar contraseña y entrar'),
                  ),
          ],
        ),
      ),
    );
  }
}
