import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class WebCompleteProfileModal extends StatelessWidget {
  const WebCompleteProfileModal({super.key});

  Future<void> _syncProfileDataToRegisterCubit(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final registerCubit = context.read<RegisterCubit>();

    if (!authState.isAuthenticated || authState.userProfile == null) return;

    final profile = authState.userProfile!;

    // Sync logic from mobile CompleteProfile
    if (profile.email.isNotEmpty) registerCubit.updateEmail(profile.email);
    if (profile.username.isNotEmpty)
      registerCubit.setUsername(profile.username);
    if (profile.displayName.isNotEmpty)
      registerCubit.setFullName(profile.displayName);

    if (profile.isPreRegistered) {
      registerCubit.markAsPreRegistered(
        username: profile.username,
        email: profile.email,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85), // Overlay backdrop
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Card background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              Image.asset(
                'assets/images/CompleteProfile.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'complete_profile.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'complete_profile.description'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Buttons Row
              Row(
                children: [
                  // Complete Now
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE97482), Color(0xFFC030A9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await _syncProfileDataToRegisterCubit(context);
                          if (!context.mounted) return;
                          final authState = context.read<AuthCubit>().state;
                          context.go(
                            '/ia-chat',
                            extra: authState.firebaseUser?.email ?? '',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'complete_profile.buttons.completeNow'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Complete Later
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<AuthCubit>()
                              .markProfileTemporarilyComplete(true);
                          // No navigation needed, state change triggers rebuild hiding modal
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'complete_profile.buttons.completeLater'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
