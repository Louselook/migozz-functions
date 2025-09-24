import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthHomeScreen extends StatefulWidget {
  const AuthHomeScreen({super.key});

  @override
  State<AuthHomeScreen> createState() => _AuthHomeScreenState();
}

class _AuthHomeScreenState extends State<AuthHomeScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  // Login manual
  Future<void> login() async {
    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Login exitoso')));
      setState(() {}); // refrescar UI
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error login: ${e.code}')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
      setState(() {}); // refrescar UI
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error cerrando sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bienvenido, ${user.email}'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: signOut,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: login,
                          child: const Text('Iniciar sesión'),
                        ),
                ],
              ),
      ),
    );
  }
}
