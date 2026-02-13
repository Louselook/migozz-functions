import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
// import 'package:migozz_app/features/tutorial/profile_tutorial_helper.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';
import 'package:migozz_app/features/profile/components/utils/loader.dart';

class ProfileWrapper extends StatefulWidget {
  final TutorialKeys tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;
  final Widget Function(
    BuildContext context,
    AuthState authState,
    TutorialKeys tutorialKeys,
    ProfileTutorialKeys? profileTutorialKeys,
  )
  builder;

  const ProfileWrapper({
    super.key,
    required this.tutorialKeys,
    this.profileTutorialKeys,
    required this.builder,
  });

  @override
  State<ProfileWrapper> createState() => _ProfileWrapperState();
}

class _ProfileWrapperState extends State<ProfileWrapper> {
  final tutorialKeys = TutorialKeys();
  // bool _tutorialShown = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Si estamos chequeando estado global -> mostrar splash neutral
        if (authState.status == AuthStatus.checking) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: LoaderDialog(message: 'common.loading'.tr())),
          );
        }

        // Usuario no autenticado
        if (!authState.isAuthenticated) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'profile.presentation.noAuthenticatedUser'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Cargando perfil
        if (authState.isLoadingProfile) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: LoaderDialog(
                message: 'edit.presentation.loadingProfile'.tr(),
              ),
            ),
          );
        }

        // ✅ El router redirect manejará la lógica de /complete-profile
        // No duplicamos aquí la redirección

        // Si perfil completo -> trigger tutorial si aplica (solo una vez)
        // if ((authState.userProfile?.complete ?? false) && !_tutorialShown) {
        //   _tutorialShown = true;
        //   WidgetsBinding.instance.addPostFrameCallback((_) async {
        //     await triggerProfileTutorial(context, widget.tutorialKeys);
        //   });
        // }

        // Si llegamos aquí, el perfil existe y está listo -> delegamos al builder
        return widget.builder(
          context,
          authState,
          widget.tutorialKeys,
          widget.profileTutorialKeys,
        );
      },
    );
  }
}
