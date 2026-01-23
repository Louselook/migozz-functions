import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class CompleteProfile extends StatelessWidget {
  const CompleteProfile({super.key});

  /// Sincroniza datos del perfil de Firestore con el RegisterCubit
  /// Esto es importante para usuarios de Google/Apple que tienen pre-registro
  Future<void> _syncProfileDataToRegisterCubit(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final registerCubit = context.read<RegisterCubit>();

    if (!authState.isAuthenticated || authState.userProfile == null) {
      debugPrint(
        '⚠️ [CompleteProfile] No hay perfil autenticado para sincronizar',
      );
      return;
    }

    final profile = authState.userProfile!;
    debugPrint(
      '🔄 [CompleteProfile] Sincronizando datos del perfil con RegisterCubit',
    );
    debugPrint('   - Email: ${profile.email}');
    debugPrint('   - Username: ${profile.username}');
    debugPrint('   - DisplayName: ${profile.displayName}');
    debugPrint('   - isPreRegistered: ${profile.isPreRegistered}');

    // Sincronizar datos básicos
    if (profile.email.isNotEmpty) {
      registerCubit.updateEmail(profile.email);
    }

    if (profile.username.isNotEmpty) {
      registerCubit.setUsername(profile.username);
    }

    if (profile.displayName.isNotEmpty) {
      registerCubit.setFullName(profile.displayName);
    }

    // Sincronizar estado de pre-registro si viene de Google/Apple con pre-order
    if (profile.isPreRegistered) {
      debugPrint(
        '✅ [CompleteProfile] Usuario viene de pre-registro con Google/Apple',
      );
      registerCubit.markAsPreRegistered(
        username: profile.username,
        email: profile.email,
      );
    }
  }

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
              const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 32),

              Text(
                'complete_profile.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'complete_profile.description'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    debugPrint('🔄 Navegar a completar perfil en IA Chat');

                    // Sincronizar datos del perfil (incluyendo pre-registro) antes de ir al chat
                    await _syncProfileDataToRegisterCubit(context);

                    final authState = context.read<AuthCubit>().state;
                    if (!context.mounted) return;
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
                  child: Text(
                    'complete_profile.buttons.completeNow'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    debugPrint('⏭️ Completar más tarde - Permitir usar la app');
                    // ✅ Marcar que el usuario ya vio este diálogo en esta sesión
                    // El diálogo no se mostrará nuevamente hasta que cierre y abra la app
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
                  child: Text(
                    'complete_profile.buttons.completeLater'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
