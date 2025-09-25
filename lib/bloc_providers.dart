import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/services/auth_service.dart';

/// Lista de providers globales de la app
final List<BlocProvider> blocProviders = [
  BlocProvider<AuthCubit>(create: (context) => AuthCubit(AuthService())),
  BlocProvider<LoginCubit>(
    create: (context) => LoginCubit(authService: AuthService()),
  ),
  BlocProvider<RegisterCubit>(
    create: (context) => RegisterCubit(AuthService()),
  ),
];
