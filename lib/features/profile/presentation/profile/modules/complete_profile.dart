import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      body: Stack(
        children: [
          // 1. Fondo Negro Base
          Positioned.fill(child: Container(color: Colors.black)),

          // 2. Glow Violeta (Arriba Izquierda)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF6A0D91,
                    ).withValues(alpha: 0.5), // Púrpura brillante
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // 3. Glow Amarillo/Dorado (Abajo Derecha - sutil)
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFC0A040,
                    ).withValues(alpha: 0.15), // Dorado sutil
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Contenido Principal
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagen Central
                  // Se usa filterQuality: FilterQuality.high para intentar mejorar la nitidez
                  // si el asset original es pequeño, esto ayuda un poco al escalar.
                  Image.asset(
                    'assets/images/CompleteProfile.png',
                    width: 200.w, // Responsive width
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (context, _, __) => const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Título
                  Text(
                    'complete_profile.title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  // Descripción
                  Text(
                    'complete_profile.description'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Espacio fijo entre texto y botones para mantenerlos agrupados
                  SizedBox(height: 48.h),

                  // Botones
                  Row(
                    children: [
                      // Botón Complete Now (Gradiente Rosa/Morado)
                      Expanded(
                        child: Container(
                          height: 35.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE97482), Color(0xFFC030A9)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              debugPrint(
                                '🔄 Navegar a completar perfil en IA Chat',
                              );
                              await _syncProfileDataToRegisterCubit(context);
                              // ignore: use_build_context_synchronously
                              final authState = context.read<AuthCubit>().state;
                              if (!context.mounted) return;
                              context.go(
                                '/ia-chat',
                                extra: authState.firebaseUser?.email ?? '',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'complete_profile.buttons.completeNow'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      // Botón Complete Later (Gris/Plata con texto OSCURO)
                      Expanded(
                        child: Container(
                          height: 35.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            // Gradiente grisáceo/plateado como en la referencia
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade600,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              debugPrint('⏭️ Completar más tarde');
                              context
                                  .read<AuthCubit>()
                                  .markProfileTemporarilyComplete(true);
                              context.go('/profile');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'complete_profile.buttons.completeLater'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333), // Texto oscuro
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
