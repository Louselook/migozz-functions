import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/tutorial/profile_tutorial_helper.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

/// ProfileWrapper centraliza:
/// - validación de estado de auth
/// - loading
/// - redirección a completar perfil
/// - trigger del tutorial (solo una vez)
///
/// Recibe un builder que dibuja el contenido final cuando el perfil está listo.
class ProfileWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, AuthState authState) builder;

  const ProfileWrapper({super.key, required this.builder});

  @override
  State<ProfileWrapper> createState() => _ProfileWrapperState();
}

class _ProfileWrapperState extends State<ProfileWrapper> {
  final tutorialKeys = TutorialKeys();
  bool _hasNavigated = false;
  bool _tutorialShown = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Si estamos chequeando estado global -> mostrar splash neutral
        if (authState.status == AuthStatus.checking) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Usuario no autenticado
        if (!authState.isAuthenticated) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No hay usuario autenticado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Cargando perfil
        if (authState.isLoadingProfile) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Si el perfil NO está completo -> redirigir a /complete-profile (solo una vez)
        if ((authState.userProfile?.complete == false) && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.push('/complete-profile');
          });

          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Redirigiendo a completar perfil...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Si perfil completo -> trigger tutorial si aplica (solo una vez)
        if ((authState.userProfile?.complete ?? false) && !_tutorialShown) {
          _tutorialShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await triggerProfileTutorial(context, tutorialKeys);
          });
        }

        // Si llegamos aquí, el perfil existe y está listo -> delegamos al builder
        return widget.builder(context, authState);
      },
    );
  }
}
