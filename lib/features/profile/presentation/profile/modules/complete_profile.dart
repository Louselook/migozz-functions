import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

class CompleteProfile extends StatelessWidget {
  const CompleteProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono o ilustración
              const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 32),

              // Título
              const Text(
                'Completa tu Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Descripción
              const Text(
                'Para aprovechar al máximo Migozz,\ncompleta tu información de perfil',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botón principal: Completar Ahora
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('🔄 Navegar a completar perfil en IA Chat');
                    final authState = context.read<AuthCubit>().state;
                    context.go(
                      '/ia-chat',
                      extra: authState.firebaseUser?.email ?? '',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Completar Ahora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón secundario: Completar Más Tarde
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    debugPrint('⏭️ Completar más tarde - Ir al perfil');

                    // Temporalmente marcar el perfil como "permitido incompleto"
                    // para que el router permita acceso al profile
                    context.read<AuthCubit>().markProfileTemporarilyComplete(
                      true,
                    );
                    context.go('/profile');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: const Text(
                    'Completar Más Tarde',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
