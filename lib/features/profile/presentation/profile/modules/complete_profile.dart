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
    // Usamos MediaQuery para tamaños relativos a la pantalla
    final size = MediaQuery.of(context).size;

    // Si la pantalla es muy pequeña (móvil pequeño), ajustamos ligeramente
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo Negro Base
          Positioned.fill(child: Container(color: Colors.black)),

          // 2. Glow Violeta (Sutil)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6A0D91).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 3. Glow Dorado (Sutil)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC0A040).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Contenido Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Imagen Central - Tamaño fijo lógico
                      Image.asset(
                        'assets/images/CompleteProfile.png',
                        width: isSmallScreen ? 120 : 140,
                        height: isSmallScreen ? 120 : 140,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        // Añadir key para forzar repintado si cambia
                        key: const ValueKey('profile_image'),
                        errorBuilder: (context, _, __) => const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      Text(
                        'complete_profile.title'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Descripción
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'complete_profile.description'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: isSmallScreen ? 13 : 14,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botones
                      Row(
                        children: [
                          // Botón Complete Now
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE97482),
                                    Color(0xFFC030A9),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE97482,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await _syncProfileDataToRegisterCubit(
                                      context,
                                    );
                                    if (!context.mounted) return;
                                    final authState = context
                                        .read<AuthCubit>()
                                        .state;
                                    context.go(
                                      '/ia-chat',
                                      extra:
                                          authState.firebaseUser?.email ?? '',
                                    );
                                  },
                                  child: Center(
                                    child: Text(
                                      'complete_profile.buttons.completeNow'
                                          .tr(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Botón Complete Later
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    context
                                        .read<AuthCubit>()
                                        .markProfileTemporarilyComplete(true);
                                    context.go('/profile');
                                  },
                                  child: Center(
                                    child: Text(
                                      'complete_profile.buttons.completeLater'
                                          .tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
