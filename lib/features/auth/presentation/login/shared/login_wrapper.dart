// lib/features/auth/presentation/login/shared/login_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/loading_overlay.dart';
import 'package:migozz_app/core/components/compuestos/custom_snackbar.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/auth/presentation/login/mobile/otp_screen.dart'
    as mobile_otp;
import 'package:migozz_app/features/auth/presentation/login/web/otp_screen.dart'
    as web_otp;
import 'package:migozz_app/core/utils/platform_utils.dart';

class LoginWrapper extends StatefulWidget {
  final Widget child;
  const LoginWrapper({super.key, required this.child});

  @override
  State<LoginWrapper> createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  bool _isLoadingVisible = false;
  bool _hasNavigatedToOTP = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Loading de LoginCubit (OTP flows)
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.isLoading != current.isLoading,
          listener: (context, state) {
            if (state.isLoading && !_isLoadingVisible) {
              _isLoadingVisible = true;
              LoadingOverlay.show(context);
            } else if (!state.isLoading && _isLoadingVisible) {
              _isLoadingVisible = false;
              LoadingOverlay.hide(context);
            }
          },
        ),

        // Listener para navegar a OTP cuando LoginCubit emite OTP
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.currentOTP != current.currentOTP &&
              current.currentOTP != null &&
              current.email != null,
          listener: (context, state) {
            if (state.currentOTP != null &&
                state.email != null &&
                !_hasNavigatedToOTP) {
              _hasNavigatedToOTP = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                // Escoger la pantalla correcta según la plataforma
                final page = PlatformUtils.isWeb
                    ? web_otp.OtpScreen(
                        email: state.email!,
                        userOTP: state.currentOTP!,
                      )
                    : mobile_otp.OtpScreen(
                        email: state.email!,
                        userOTP: state.currentOTP!,
                      );

                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => page,
                    transitionsBuilder: (_, animation, __, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                ).then((_) {
                  _hasNavigatedToOTP = false;
                });
              });
            }
          },
        ),

        // Errores desde LoginCubit
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.errorMessageLogin != current.errorMessageLogin,
          listener: (context, state) {
            if (state.errorMessageLogin != null &&
                state.errorMessageLogin!.isNotEmpty) {
              CustomSnackbar.show(
                context: context,
                message: state.errorMessageLogin!,
                type: SnackbarType.error,
              );
            }
          },
        ),

        // Cuando AuthCubit autentica, navegar al profile
        // El router se encargará de redirigir a /complete-profile si el perfil está incompleto
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              current.isAuthenticated && !previous.isAuthenticated,
          listener: (context, state) {
            // Navegar siempre que el usuario esté autenticado
            // El router redirect manejará si debe ir a /complete-profile o /profile
            debugPrint('🔐 [LoginWrapper] Usuario autenticado, navegando a /profile');
            debugPrint('🔐 [LoginWrapper] userProfile: ${state.userProfile}');
            debugPrint('🔐 [LoginWrapper] userProfile.complete: ${state.userProfile?.complete}');
            context.go('/profile');
          },
        ),
      ],
      child: widget.child,
    );
  }
}
